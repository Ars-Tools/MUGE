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
public struct MTLArtwork {
    let color: MTLClearColor
    let extra: MTLPixelFormat
    let source: Array<`Protocol`>
}
extension MTLArtwork: Artwork {
    public func callAsFunction(as format: MTLPixelFormat, in residency: MTLResidencySet, signal: some Publisher<(SIMD2<Float64>, Gesture), Never>) throws -> @Sendable (CFTimeInterval, MTL4CommandBuffer, MTLTexture) -> Void {
        let kernel = try source.map {
            try $0.callAsFunction(as: format, in: residency, signal: signal)
        }
        switch extra {
        case.stencil8:
            assertionFailure("not implemented")
            fallthrough
        case.depth32Float_stencil8, .depth24Unorm_stencil8:
            assertionFailure("not implemented")
            fallthrough
        case.depth32Float, .depth16Unorm:
            assertionFailure("not implemented")
            fallthrough
        default:
            return { [color] in
                let descriptor = MTL4RenderPassDescriptor()
                descriptor.colorAttachments[0].texture = $2
                descriptor.colorAttachments[0].clearColor = color
                descriptor.colorAttachments[0].loadAction = .clear
                descriptor.colorAttachments[0].storeAction = .store
                if case.some(let encoder) = $1.makeRenderCommandEncoder(descriptor: descriptor) {
                    for kernel in kernel {
                        kernel($0, encoder)
                    }
                    encoder.endEncoding()
                }
            }
        }
    }
}
extension MTLArtwork {
    public protocol `Protocol`: Artwork {
        @inlinable
        func callAsFunction(as format: MTLPixelFormat, in residency: MTLResidencySet, signal: some Publisher<(SIMD2<Float64>, Gesture), Never>) throws -> @Sendable (CFTimeInterval, MTL4RenderCommandEncoder) -> Void
    }
}
extension MTLArtwork.`Protocol` {
    public func callAsFunction(as format: MTLPixelFormat, in residency: any MTLResidencySet, signal: some Publisher<(SIMD2<Float64>, Gesture), Never>) throws -> @Sendable (CFTimeInterval, any MTL4CommandBuffer, any MTLTexture) -> Void {
        try MTLArtwork(color: .init(), extra: .r8Unorm, source: [self]).callAsFunction(as: format, in: residency, signal: signal)
    }
}

//public protocol MTLArtwork: Artwork {
//    @inlinable
//    var stencil: UInt32 { get }
//    @inlinable
//    var colour: MTLClearColor { get }
//    @inlinable
//    var depth: Float64 { get }
//    @inlinable
//    func callAsFunction(as format: MTLPixelFormat, in residency: MTLResidencySet, signal: some Publisher<(SIMD2<Float64>, Gesture), Never>) throws -> @Sendable (CFTimeInterval, MTL4RenderCommandEncoder) -> Void
//}
//extension MTLArtwork {
//    @inlinable
//    public var stencil: UInt32 { 0 }
//    @inlinable
//    public var colour: MTLClearColor { .init(red: 0, green: 0, blue: 0, alpha: 1) }
//    @inlinable
//    public var depth: Float64 { 1 }
//}
//extension MTLArtwork {
//    public func callAsFunction(as format: MTLPixelFormat, in residency: any MTLResidencySet, signal: some Publisher<(SIMD2<Float64>, Gesture), Never>) throws -> @Sendable (CFTimeInterval, any MTL4CommandBuffer, any MTLTexture) -> Void {
//        let additional = MTLHeapDescriptor()
//        additional.storageMode = .private
//        additional.size = 15_360 * 8_640 * 8 * 3
//        guard case.some(let memory) = residency.device.makeHeap(descriptor: additional) else {
//            throw MTLLibraryError(.internal)
//        }
//        residency.addAllocation(memory)
//        let drawer = try callAsFunction(as: format, in: residency, signal: signal)
//        return { [stencil, colour, depth] in
//            let optional = .texture2DDescriptor(pixelFormat: .depth32Float_stencil8,
//                                                width: $2.width,
//                                                height: $2.height,
//                                                mipmapped: false) as MTLTextureDescriptor
//            optional.usage = .renderTarget
//            let texture = memory.makeTexture(descriptor: optional)
//            let descriptor = MTL4RenderPassDescriptor()
//            descriptor.colorAttachments[0].texture = $2
//            descriptor.colorAttachments[0].loadAction = .clear
//            descriptor.colorAttachments[0].storeAction = .store
//            descriptor.colorAttachments[0].clearColor = colour
//            descriptor.stencilAttachment.clearStencil = stencil
//            descriptor.stencilAttachment.texture = texture
//            descriptor.depthAttachment.clearDepth = depth
//            descriptor.depthAttachment.texture = texture
//            if case.some(let encoder) = $1.makeRenderCommandEncoder(descriptor: descriptor) {
//                drawer($0, encoder)
//                encoder.endEncoding()
//            }
//        }
//    }
//}
public protocol MTXArtwork: Artwork {
    @inlinable
    func callAsFunction(in residency: MTLResidencySet, signal: some Publisher<(SIMD2<Float64>, Gesture), Never>) throws -> (MTLTextureDescriptor, @Sendable (CFTimeInterval, MTL4CommandBuffer) -> MTLTexture)
}
extension MTXArtwork {
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
