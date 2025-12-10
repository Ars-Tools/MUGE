//
//  Protocol.swift
//  MUGE
//
//  Created by Kota on 12/9/25.
//
@preconcurrency import MetalKit
import Artwork
import CIArtwork
public protocol CGArtwork: CIArtwork {
    func cgImage(at: CFTimeInterval) -> Optional<CGImage>
}
extension CGArtwork {
    @inlinable
    public func ciImage(at timeline: CFTimeInterval) -> Optional<CIImage> {
        cgImage(at: timeline).map(CIImage.init(cgImage:))
    }
}
//extension CGImage: MTLArtwork & Artwork {
//    @usableFromInline
//    enum Error: Swift.Error {
//        case noImage
//    }
//    public func callAsFunction(in residency: any MTLResidencySet, signal: some Publisher<(SIMD2<Double>, any Gesture), Never>) throws -> (MTLTextureDescriptor, @Sendable (CFTimeInterval, MTL4CommandBuffer) -> MTLTexture) {
//        guard let cgImage else {
//            throw Error.noImage
//        }
//        let texture = try MTKTextureLoader(device: residency.device).newTexture(cgImage: cgImage)
//        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: texture.pixelFormat,
//                                                                  width: texture.width,
//                                                                  height: texture.height,
//                                                                  mipmapped: texture.mipmapLevelCount > 0)
//        return (descriptor, { [texture] _, _ in texture })
//    }
//    public func callAsFunction(as format: MTLPixelFormat, in residency: any MTLResidencySet, signal: some Publisher<(SIMD2<Double>, any Gesture), Never>) throws -> @Sendable (CFTimeInterval, any MTL4CommandBuffer, any MTLTexture) -> Void {
//        fatalError()
//    }
//}
