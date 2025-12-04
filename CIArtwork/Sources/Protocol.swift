//
//  Protocol.swift
//  MUGE
//
//  Created by Kota on 12/3/25.
//
import protocol SwiftUI.Gesture
@preconcurrency import protocol Combine.Publisher
@preconcurrency import CoreImage
import Artwork
import os.log
public protocol CIArtwork: Artwork {
    var outputImage: Optional<CIImage> { get }
}
extension CIArtwork where Self: Sendable {
    public func callAsFunction(as format: MTLPixelFormat, in residency: MTLResidencySet, signal: some Publisher<(SIMD2<Float64>, Gesture), Never>) throws -> @Sendable (CFTimeInterval, MTL4CommandBuffer, MTLTexture) -> Void {
        let ctx = CIContext(mtlDevice: residency.device)
        return switch outputImage {
        case.some(let image):
            {
                do {
                    try ctx.startTask(toRender: image, to: .init(mtlTexture: $2, commandBuffer: .none))
                } catch {
                    
                }
            }
        case.none:
            fatalError()
        }
    }
}
extension CIFilter: CIArtwork {}
extension CIImage: CIArtwork {
    public var outputImage: Optional<CIImage> { .some(self) }
}
