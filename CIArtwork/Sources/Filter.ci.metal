//
//  Filter.ci.metal
//  MUGE
//
//  Created by Kota on 12/9/25.
//
#include<CoreImage/CoreImage.h>
using namespace coreimage;
extern "C" {
    float4 myColor(sample_t s, float2 val) {
        return s.ggga * val.xxyy;
    }
    float2 myWarp(destination dest) {
        return dest.coord();
    }
    float4 myBlend(sample_t foreground, sample_t background) {
        return (foreground + background) / 2.0;
    }
//    float4 myKernel(coreimage::sampler src) {
//        return src.sample(src.coord());
//    }
}
