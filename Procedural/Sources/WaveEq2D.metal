//
//  WaveEq2D.metal
//  MUGE
//
//  Created by Kota on 12/10/25.
//
#include<metal_stdlib>
using namespace metal;
constant float factor [[ function_constant(0) ]];
[[kernel]]
void waveeq2d(texture2d_array<float, access::read_write> const field [[ texture(0) ]],
              constant uint const & index [[ buffer(0) ]],
              uint2 const x [[ thread_position_in_grid ]]) {
    uint2 const X {field.get_width(), field.get_height()};
    if ( all(0 < x) && all(x < X - 1) ) {
        uint const T = field.get_array_size();
        uint const f = ( ( index + T - 0 ) % T + T ) % T;
        uint const c = ( ( index + T - 1 ) % T + T ) % T;
        uint const p = ( ( index + T - 2 ) % T + T ) % T;
        
        float const cx = field.read(x, c).x;
        float const dx = - 4.0 * cx +
        field.read(x + uint2(0, 1), c).x +
        field.read(x - uint2(0, 1), c).x +
        field.read(x + uint2(1, 0), c).x +
        field.read(x - uint2(1, 0), c).x;
        
        field.write(factor * (2.0 * cx - field.read(x, p).x + 0.5 * dx), x, f);
        
    }
}
