//
//  Blit.metal
//  MUGE
//
//  Created by Kota on 12/8/25.
//
#include<metal_stdlib>
using namespace metal;
constant sampler reshape(filter::linear, address::clamp_to_zero);
constant float2 const scale [[ function_constant(0) ]];
struct stage {
    float4 position [[position]];
    float2 uv;
};

[[vertex]]
stage billboard(uint const vid [[vertex_id]],
                texture2d<float, access::sample>const tex) {
    float const w = tex.get_width();
    float const h = tex.get_height();
    uint2 const uv {vid % 2, vid / 2};
    return {
        .position=float4(min(1.0, float2(w / h, h / w)) * scale * fma(float2(uv), 2, -1), 0, 1),
        .uv=float2(uv)
    };
}

[[visible]] float3 view0(float2 const);
[[visible]] float3 view1(float2 const, texture2d<float, access::sample>const);
[[visible]] float3 view2(float2 const, texture2d<float, access::sample>const, texture2d<float, access::sample>const);

[[stitchable]]
float3 const RGB2RGB(float2 const uv, texture2d<float, access::sample>const rgb) {
    return rgb.sample(reshape, uv).xyz;
}

[[stitchable]]
float3 const YCbCr2RGB(float2 const uv, texture2d<float, access::sample>const y, texture2d<float, access::sample>const c) {
    return (float4x4(float4(1.16438,  1.16438,  1.16438, 0.0),
                     float4(0.00000, -0.39176,  2.01723, 0.0),
                     float4(1.59603, -0.81297,  0.00000, 0.0),
                     float4(-0.87420, 0.53565, -1.08563, 1.0)) * float4(y.sample(reshape, uv).x, c.sample(reshape, uv).xy, 1)).xyz;
}

[[fragment]] // null-plane
half4 fragment0(stage in [[ stage_in ]]) {
    return half4(half3(view0(in.uv)), 1);
}

[[fragment]] // uni-plane
half4 fragment1(stage in [[ stage_in ]],
                texture2d<float, access::sample> plane0 [[ texture(0) ]]) {
    return half4(half3(view1(in.uv, plane0)), 1);
}

[[fragment]] // bi-plane
half4 fragment2(stage in [[ stage_in ]],
                texture2d<float, access::sample> plane0 [[ texture(0) ]],
                texture2d<float, access::sample> plane1 [[ texture(1) ]]) {
    return half4(half3(view2(in.uv, plane0, plane1)), 1);
}
