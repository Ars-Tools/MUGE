//
//  Gray-Scott.swift
//  MUGE
//
//  Created by Kota on 12/11/25.
//
@preconcurrency import Metal
@preconcurrency import Artwork
public struct GrayScott {
    @usableFromInline let size: SIMD2<Int>
}
extension GrayScott: MTLArtwork {
    public func callAsFunction(in residency: any MTLResidencySet, signal: some Publisher<(SIMD2<Double>, any Gesture), Never>) throws -> (MTLTextureDescriptor, @Sendable (CFTimeInterval, any MTL4CommandBuffer) -> any MTLTexture) {
        
        fatalError()
    }
}
