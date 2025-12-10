//
//  Protocol.swift
//  MUGE
//
//  Created by Kota on 12/3/25.
//
@_exported import protocol SwiftUI.Gesture
@_exported @preconcurrency import protocol Combine.Publisher
@_exported @preconcurrency import Metal
import func simd.min
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
public protocol MTLArtwork: Artwork {
    @inlinable
    func callAsFunction(in residency: MTLResidencySet, signal: some Publisher<(SIMD2<Float64>, Gesture), Never>) throws -> (MTLTextureDescriptor, @Sendable (CFTimeInterval, MTL4CommandBuffer) -> MTLTexture)
}
extension MTLArtwork {
    public func callAsFunction(as format: MTLPixelFormat, in residency: any MTLResidencySet, signal: some Publisher<(SIMD2<Float64>, Gesture), Never>) throws -> @Sendable (CFTimeInterval, any MTL4CommandBuffer, any MTLTexture) -> Void {
        let (descriptor, generator) = try callAsFunction(in: residency, signal: signal)
        let w = Float64(descriptor.width)
        let h = Float64(descriptor.height)
        let blit = try Blit.Uni(with: residency.device.makeCompiler(descriptor: .init()),
                                to: format, scale: min(.one, .init(.init(h / w), .init(w / h))), name: "RGB2RGB")
        let resource = try residency.device.makeResidencySet(descriptor: .init())
        return {
            resource.removeAllAllocations()
            let texture = generator($0, $1)
            resource.addAllocation(texture)
            blit.render(to: $2, with: $1, primary: texture)
            resource.commit()
            $1.useResidencySet(resource)
        }
    }
}
