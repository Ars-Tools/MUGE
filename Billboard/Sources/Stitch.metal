//
//  Stitch.swift
//  MUGE
//
//  Created by Kota on 12/7/25.
//
#include<metal_stdlib>
#include"Screen.h"
using namespace metal;

[[stitchable]]
float sdfSphere(float3 const p, float const radius) {
    return length(p) - radius;
}

// 箱
[[stitchable]]
float sdfBox(float3 const p, float3 const size) {
    float3 q = abs(p) - size;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// 繰り返し (Modulo)
[[stitchable]]
float3 opRepeat(float3 const p, float3 const spacing) {
    return p - spacing * floor(p / spacing + 0.5);
}

// 差分 (A - B)
[[stitchable]]
float opSubtract(float const d1, float const d2) {
    return max(-d1, d2);
}

// ----------------------------------------------------------------
// 3. Fragment Engine (レイマーチング本体)
// ----------------------------------------------------------------

// グラフ関数のシグネチャ定義
// Swiftで作るグラフは「座標(float3)と時間(float)」を受け取り「距離(float)」を返すものとします
//using SDF_Function = function<float(float3, float)>;
using SDF_Graph = float(float3, float);

[[fragment]]
float4 stfs(VertexOut in [[stage_in]],
            constant float &uni [[buffer(0)]],
            visible_function_table<float(float3, float)> sdfTable [[buffer(1)]])
{
    float2 uv = in.uv;
    uv.x *= 1;

    float3 ro = float3(0.0, 0.0, 4.0);
    float3 rd = normalize(float3(uv, -1.5));

    // ★修正3: テーブルから関数を取得
    // 型は "SDF_Graph" ではなく、テーブルが返す "function object" です。
    // "auto" を使うのが最も安全でモダンな書き方です。
    auto map = sdfTable[0];

    // レイマーチング
    float t = 0.0;
    float3 col = float3(0.0);
    
    for(int i = 0; i < 64; i++) {
        float3 p = ro + rd * t;
        
        // 関数実行
        float d = map(p, uni);
        
        if(d < 0.001) {
            float glow = float(i) / 64.0;
            col = float3(1.0, 0.4, 0.1) * (1.0 - glow);
            break;
        }
        t += d;
        if(t > 20.0) break;
    }

    return float4(col, 1.0);
}
