//
//  Lines.metal
//  MUGE
//
//  Created by Kota on 12/12/25.
//
#include<metal_stdlib>
using namespace metal;
constant uint const N [[ function_constant(0) ]];
typedef struct Stage {
    float4 const position [[ position ]];
};
[[vertex]]
Stage line2Dvs(constant float * const x [[ buffer(0) ]],
               constant float * const y [[ buffer(1) ]],
               constant uint const k [[ buffer(2) ]],
               uint const iid [[ instance_id ]],
               uint const vid [[ vertex_id ]]) {
    return {
        .position=float2(x[iid * N + ( vid + k ) % N],
                         y[iid * N + ( vid + k ) % N])
    };
}
[[fragment]]
half4 line2Dfs(Stage in [[ stage_in ]]) {
    return 1.0;
}
