//
//  App.metal
//  MUGE
//
//  Created by Kota on 1/7/26.
//
#include<metal_stdlib>
using namespace metal;
struct StageIn {
    float4 position [[ position ]];
};
[[fragment]]
half4 white(StageIn stage_in [[ stage_in ]]) {
    return {1, 1, 1, 1};
}
int constant MAX_PRIMITIVE = 64;
int constant MAX_VERTICES = 2 * MAX_PRIMITIVE;
// metal::mesh<V, P, NV, NP, t>
//  V  - vertex type (output struct)
//  P  - primitive type (output struct)
//  NV - max number of vertices
//  NP - max number of primitives
//  t  - topology
[[mesh]]
void xaxis(mesh<StageIn, void, MAX_VERTICES, MAX_PRIMITIVE, topology::line> out,
           float constant * const buffer [[ buffer(0) ]],
           uint constant const & length [[ buffer(1) ]],
           uint const lid [[ thread_position_in_threadgroup ]],
           uint const gid [[ thread_position_in_grid ]]) {
    switch ( lid ) {
        case 0:
            out.set_primitive_count(min(MAX_PRIMITIVE, int(length) - int(gid)));
        default:
            uint2 const idx = 2 * lid + uint2 { 0, 1 };
            out.set_vertex(idx[0], { { buffer[lid], -1.0, 0.0, 1.0 } });
            out.set_vertex(idx[1], { { buffer[lid],  1.0, 0.0, 1.0 } });
            out.set_index(idx[0], idx[0]);
            out.set_index(idx[1], idx[1]);
    }
}
[[mesh]]
void yaxis(mesh<StageIn, void, MAX_VERTICES, MAX_PRIMITIVE, topology::line> out,
           float constant * const buffer [[ buffer(0) ]],
           uint constant const & length [[ buffer(1) ]],
           uint const lid [[ thread_position_in_threadgroup ]],
           uint const gid [[ thread_position_in_grid ]]) {
    switch ( lid ) {
        case 0:
            out.set_primitive_count(min(64, int(length) - int(gid)));
        default:
            uint2 const idx = 2 * lid + uint2 { 0, 1 };
            out.set_vertex(idx[0], { { -1.0, buffer[lid], 0.0, 1.0 } });
            out.set_vertex(idx[1], { {  1.0, buffer[lid], 0.0, 1.0 } });
            out.set_index(idx[0], idx[0]);
            out.set_index(idx[1], idx[1]);
    }
}
