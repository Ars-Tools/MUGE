//
//  Protocol.swift
//  MUGE
//
//  Created by Kota on 12/3/25.
//
@_exported @preconcurrency import CoreImage
@_exported @preconcurrency import CoreImage.CIFilterBuiltins
@preconcurrency import protocol Combine.Publisher
import Artwork
import os.log
public protocol CIArtwork: Artwork {
    func ciImage(at: CFTimeInterval) -> Optional<CIImage>
}
extension CIArtwork where Self: Sendable {
    public func callAsFunction(as format: MTLPixelFormat, in residency: MTLResidencySet, signal: some Publisher<(SIMD2<Float64>, Gesture), Never>) throws -> @Sendable (CFTimeInterval, MTL4CommandBuffer, MTLTexture) -> Void {
        let device = residency.device
        let fence = device.makeFence().unsafelyUnwrapped
        let mtlCommandQueue = device.makeCommandQueue().unsafelyUnwrapped
        let ciContext = CIContext(mtlCommandQueue: mtlCommandQueue)
        return {
            switch ciImage(at: $0) {
            case.some(let image):
                do {
                    let mtlCommandBuffer = mtlCommandQueue.makeCommandBuffer()
                    try ciContext.startTask(toRender: image,
                                            to: .init(mtlTexture: $2, commandBuffer: mtlCommandBuffer))
                    let encoder = mtlCommandBuffer?.makeBlitCommandEncoder()
                    encoder?.synchronize(resource: $2)
                    encoder?.updateFence(fence)
                    encoder?.endEncoding()
                    mtlCommandBuffer?.commit()
                } catch {
                    return
                }
                do {
                    let encoder = $1.makeComputeCommandEncoder()
                    encoder?.waitForFence(fence, beforeEncoderStages: .blit)
                    encoder?.optimizeContents(forGPUAccess: $2)
                    encoder?.endEncoding()
                }
            case.none:
                break
            }
        }
    }
}
extension CIImage: CIArtwork {
    public func ciImage(at: CFTimeInterval) -> Optional<CIImage> {
        .some(self)
    }
}
extension CIFilter: CIArtwork {
    public func ciImage(at: CFTimeInterval) -> Optional<CIImage> {
        outputImage
    }
}
