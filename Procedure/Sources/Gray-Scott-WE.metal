//
//  Gray-Scott-WE.metal
//  MUGE
//
//  Created by Kota on 12/4/25.
//
#include<metal_stdlib>
using namespace metal;
constant float f [[ function_constant(0) ]];
constant float k [[ function_constant(1) ]];
constant float Du [[ function_constant(2) ]];
constant float Dv [[ function_constant(3) ]];
constant float dx [[ function_constant(4) ]];
constant float dt [[ function_constant(5) ]];
struct VertexOut {
    float4 position [[ position ]];
    float2 coord;
};
kernel void gswecc(texture2d_array<float, access::read_write> const field [[ texture(0) ]],
                   uint2 const i [[ thread_position_in_grid ]]) {
    field.write(field.read(i, 3).x * (8191.0 / 8192.0), i, 4);
    field.write(field.read(i, 2).x * (8191.0 / 8192.0), i, 3);
}
kernel void gswecs(texture2d_array<float, access::read_write> const field [[ texture(0) ]],
                   uint2 const i [[ thread_position_in_grid ]]) {
    uint2 const X = uint2(field.get_width(), field.get_height());
    if ( any(i<1) || any(X-2 < i) ) return;
    
    // we-fdtd
//    f(t+1,x)=f(t,x-1)+f(t,x+1)-f(t-1,x)
    float const u = field.read(i, 0).x;
    float const v = field.read(i, 1).x;
    float const x = field.read(i, 3).x;
    float const p = field.read(i, 4).x;
    
    float const xp = field.read(i + uint2(1, 0), 3).x;
    float const xn = field.read(i - uint2(1, 0), 3).x;
    
    float const yp = field.read(i + uint2(0, 1), 3).x;
    float const yn = field.read(i - uint2(0, 1), 3).x;
    
    float const n = max(0.0, min(1.0, u)) * ( xp + xn + yp + yn - 4 * x ) / 2 - p + 2 * x;
    field.write(n, i, 2);
    
    // gray-scott
    
    float const lu = (field.read(i + uint2(0, 1), 0).x +
                      field.read(i - uint2(0, 1), 0).x +
                      field.read(i + uint2(1, 0), 0).x +
                      field.read(i - uint2(1, 0), 0).x -
                      4 * u) / dx / dx;
    float const lv = (field.read(i + uint2(0, 1), 1).x +
                      field.read(i - uint2(0, 1), 1).x +
                      field.read(i + uint2(1, 0), 1).x +
                      field.read(i - uint2(1, 0), 1).x -
                      4 * v) / dx / dx;
    float const dudt = Du * lu - u * v * v + f * ( 1 - u );
    float const dvdt = Dv * lv + u * v * v - ( f + k ) * v;
    field.write(u + dt * (dudt + min(0.0, 3e-3 * n)), i, 0);
    field.write(v + dt * (dvdt - max(0.0, 3e-3 * n)), i, 1);
    
}
vertex VertexOut gswevs(device float2 const * const x [[ buffer(0) ]],
                        device uint const & r [[ buffer(1) ]],
                        uint const n [[ vertex_id ]]) {
    float const c = cospi(r * 0.01);
    float const s = sinpi(r * 0.01);
    return {
        .position=float4(float2x2(c, s, -s, c) * fma(x[n], 2, -1), 0, 1),
        .coord=x[n]
    };
}
fragment float4 gswefs(VertexOut const vbo [[ stage_in ]],
                       texture2d_array<float, access::sample> const field [[ texture(0) ]]) {
    float const u = field.sample(sampler(address::clamp_to_zero, filter::nearest), vbo.coord, 0).x;
    float const v = field.sample(sampler(address::clamp_to_zero, filter::nearest), vbo.coord, 1).x;
    float const x = field.sample(sampler(address::clamp_to_zero, filter::nearest), vbo.coord, 2).x;
    float const w = 1 - max(0.0, min(1.0,  1 - u )) * max(0.0, min(1.0, 1 - abs(x)));
    return float4(u, u, w, 1);
}
