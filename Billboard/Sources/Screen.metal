//
//  Screen.metal
//  MUGE
//
//  Created by Kota on 12/7/25.
//
#include<metal_stdlib>
#include"Screen.h"
using namespace metal;
[[vertex]]
VertexOut board(uint const vid [[vertex_id]]) {
    uint2 const uv {vid % 2, vid / 2};
    return {
        .position=float4(fma(float2(uv), 2.0, -1.0), 0, 1),
        .uv=float2(uv)
    };
}
[[fragment]]
float4 gradient(VertexOut in [[stage_in]]) {
    return float4(in.uv, 0.5, 1.0);
}
