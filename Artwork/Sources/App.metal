//
//  App.metal
//  MUGE
//
//  Created by Kota on 12/8/25.
//
#include<metal_stdlib>
#include<SwiftUI/SwiftUI_Metal.h>
using namespace metal;
float const mod(float const x, float const y) {
    return fmod(fmod(x, y) + y, y);
}
float3 const mod3(float3 const x, float const y) {
    return fmod(fmod(x, y) + y, y);
}
float2x2 const rot(float const a) {
    float const s = sin(a), c = cos(a);
    return float2x2(c, -s, s, c);
}

// ボックスの距離関数 (SDF)
float const sdf(float3 const p, float3 const b) {
    float3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

//[[stitchable]]
float map(float3 p) {
    // A. 空間の繰り返し（無限トンネル化）
    // Z方向に 4.0 間隔で空間をループさせる
    float zRepeat = 4.0;
    p.z = mod(p.z, zRepeat) - zRepeat * 0.5;

    // B. メンガースポンジ（フラクタル生成）
    float d = sdf(p, float3(1.0)); // 基本となる大きな箱
    float s = 1.0;
    
    // 3回のイテレーションで穴を開けていく
    for(int m = 0; m < 6; m++) {
        // 空間を分割して折り畳む
        float3 a = mod3(p * s, 2.0) - 1.0;
        s *= 4.0;
        float3 r = abs(1.0 - 4.0 * abs(a));
        
        float da = max(r.x, r.y);
        float db = max(r.y, r.z);
        float dc = max(r.z, r.x);
        float c = (min(da, min(db, dc)) - 1.0) / s;
        
        // 既存の形状から十字の穴をくり抜く (max(d, -c) ではなく max(d, c) なのはSDFの性質による)
        d = max(d, c);
    }
    
    return d;
}

// ----------------------------------------------------------------
// 5. フラグメントシェーダ (Fragment Shader)
// ----------------------------------------------------------------

[[stitchable]]
half4 spongex(float2 const in,
              SwiftUI::Layer layer,
              float4 const bb,
              float const uni) {
    // UV座標の取得
    float2 const uv = fma(in / bb.zw, 2, -1);
    
    // カメラの設定
    // Z方向に時間経過で進ませる
    float3 ro = float3(0.0, 0.0, -uni * 0.1);
    float3 rd = normalize(float3(uv, 2)); // Z=1.5 は画角(FOV)調整
    
    // 視界を少し回転させて浮遊感を出す
    rd.xy = rot(uni * 0.1) * rd.xy;
    
    // レイマーチング・ループ
    float t = 0.0;
    float3 col = float3(0.1); // 背景色（暗いグレー）
    
    for(int i = 0; i < 80; i++) { // ループ回数80回
        float3 p = ro + rd * t;
        float d = map(p);
        
        // 衝突判定 (物体表面に非常に近づいたか)
        if(d < 0.001) {
            // 色の計算
            // イテレーション回数(i)を輝度に使って擬似的なアンビエントオクルージョン効果を出す
            float glow = float(i) / 80.0;
            
            // オレンジ色の発光体 (RGB)
            float3 baseColor = float3(1.0, 0.6, 0.2);
            col = baseColor * (1.0 - glow * 0.8);
            
            // 距離フォグ：遠くを暗くして無限の奥行き感を出す
            col *= 1.0 / (1.0 + t * t * 0.1);
            
            break; // 描画終了
        }
        
        t += d; // 安全な距離だけ進む
        
        // 遠すぎる場合は打ち切り
        if(t > 40.0) break;
    }
    
    return half4(half3(col), 1.0);
//    return half4(half3(0.0), 1.0);
}
