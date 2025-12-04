//
//  Protocol.swift
//  MUGE
//
//  Created by Kota on 12/3/25.
//
import protocol SwiftUI.Gesture
@preconcurrency import Metal
@preconcurrency import protocol Combine.Publisher
public protocol Artwork: Sendable {
    @inlinable
    func callAsFunction(as format: MTLPixelFormat, in residency: MTLResidencySet, signal: some Publisher<(SIMD2<Float64>, Gesture), Never>) throws -> @Sendable (CFTimeInterval, MTL4CommandBuffer, MTLTexture) -> Void
}
extension MTLClearColor: Artwork {
    public func callAsFunction(as format: MTLPixelFormat, in residency: MTLResidencySet, signal: some Publisher<(SIMD2<Float64>, Gesture), Never>) throws -> @Sendable (CFTimeInterval, MTL4CommandBuffer, MTLTexture) -> Void {
        {
            let descriptor = MTL4RenderPassDescriptor()
            descriptor.colorAttachments[0].clearColor = self
            descriptor.colorAttachments[0].storeAction = .store
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].texture = $2
            let encoder = $1.makeRenderCommandEncoder(descriptor: descriptor)
            encoder?.endEncoding()
        }
    }
}
