//
//  NBody.metal
//  MUGE
//
//  Created by Kota on 12/12/25.
//
#include<metal_stdlib>
using namespace metal;
constant uint const M [[ function_constant(0) ]];
constant uint const N [[ function_constant(1) ]];
constant float const Gf [[ function_constant(2) ]];
constant float const dt [[ function_constant(3) ]];
struct Stage {
    float4 const position [[ position ]];
};
//float clamp(float m, float M, float x) {
//    return max(m, min(M, x));
//}
[[kernel]]
void nbody2Dc(float device * const px [[ buffer(0) ]],
              float device * const py [[ buffer(1) ]],
              uint device const & t [[ buffer(2) ]],
              float device * const vx [[ buffer(3) ]],
              float device * const vy [[ buffer(4) ]],
              float constant * const mm [[ buffer(5) ]],
              uint const m [[ thread_position_in_grid ]]) {
    if ( m < M ) {
        uint const o = m * N;
        uint const n = t % N;
        float2 const p(px[n+o], py[n+o]);
        float2 a = -p;
        for ( uint k = 0 ; k < M ; ++ k ) if ( k != m ) {
            float2 const q(px[n + k * N], py[n + k * N]);
            float2 const d = q - p;
            float const l = max(length(d), 1e-6);
            a += Gf * mm[k] * d / l / l / l;
        }
        vx[m] = vx[m] + dt * a.x;
        vy[m] = vy[m] + dt * a.y;
        px[(t+1)%N + o] = px[n+o] + dt * vx[m];
        py[(t+1)%N + o] = py[n+o] + dt * vy[m];
    }
}
[[vertex]]
Stage nbody2Dv(float constant * const px [[ buffer(0) ]],
               float constant * const py [[ buffer(1) ]],
               uint constant const & t [[ buffer(2) ]],
               uint const iid [[ instance_id ]],
               uint const vid [[ vertex_id ]]) {
    return {
        .position=float4(px[iid*N+(vid+t+2)%N],
                         py[iid*N+(vid+t+2)%N], 0, 1)
    };
}
[[fragment]]
half4 nbody2Df(Stage in [[ stage_in ]]) {
    return 1;
}
