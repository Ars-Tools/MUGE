//
//  Camera.swift
//  MUGE
//
//  Created by Kota on 12/7/25.
//
@preconcurrency import typealias Foundation.NSObject
@preconcurrency import typealias CoreVideo.CVImageBuffer
@preconcurrency import typealias AVFoundation.AVCaptureSession
@preconcurrency import typealias AVFoundation.AVCaptureDevice
@preconcurrency import typealias AVFoundation.AVCaptureDeviceInput
@preconcurrency import typealias AVFoundation.AVCaptureOutput
@preconcurrency import typealias AVFoundation.AVCaptureVideoDataOutput
@preconcurrency import typealias AVFoundation.AVCaptureConnection
@preconcurrency import protocol AVFoundation.AVCaptureVideoDataOutputSampleBufferDelegate
@preconcurrency import typealias CoreMedia.CMSampleBuffer
@preconcurrency import func CoreMedia.CMSampleBufferGetImageBuffer
@preconcurrency import func CoreMedia.CMSampleBufferGetPresentationTimeStamp
@preconcurrency import let CoreVideo.kCVPixelBufferPixelFormatTypeKey
@preconcurrency import let CoreVideo.kCVPixelFormatType_32BGRA
@preconcurrency import typealias Combine.CurrentValueSubject
@preconcurrency import protocol Combine.Publisher
@preconcurrency import protocol Combine.Subscriber
@preconcurrency import CoreImage
import Artwork
import CIArtwork
import Synchronization
public final class Camera: NSObject, @unchecked Sendable {
    enum Error: Swift.Error {
        case Input
        case Output
    }
    @usableFromInline
    let avCaptureSession: AVCaptureSession
    public let cvImageBufferSubject: CurrentValueSubject<Optional<CVImageBuffer>, Never>
    public init(device: AVCaptureDevice) throws {
        avCaptureSession = .init()
        cvImageBufferSubject = .init(.none)
        super.init()
        let input = try AVCaptureDeviceInput(device: device)
        guard avCaptureSession.canAddInput(input) else { throw Error.Input }
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: .global(qos: .userInitiated))
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [:]
//        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA] // MPS-Compatible
        guard avCaptureSession.canAddOutput(output) else { throw Error.Output }
        avCaptureSession.beginConfiguration()
        avCaptureSession.addInput(input)
        avCaptureSession.addOutput(output)
        avCaptureSession.commitConfiguration()
        avCaptureSession.startRunning()
    }
    deinit {
        avCaptureSession.stopRunning()
    }
}
extension Camera: AVArtwork {
    @inlinable
    public func start() {
        avCaptureSession.startRunning()
    }
    @inlinable
    public func stop() {
        avCaptureSession.stopRunning()
    }
    @inlinable
    public func cvImageBuffer(at timestamp: CFTimeInterval) -> Optional<CVImageBuffer> {
        cvImageBufferSubject.value
    }
}
extension Camera: Artwork {
    public func callAsFunction(as format: MTLPixelFormat, in residency: any MTLResidencySet, signal: some Publisher<(SIMD2<Double>, any Gesture), Never>) throws -> @Sendable (CFTimeInterval, any MTL4CommandBuffer, any MTLTexture) -> Void {
        let device = residency.device
        var memory: CVMetalTextureCache?
        guard CVMetalTextureCacheCreate(kCFAllocatorDefault, .none, device, .none, &memory) == 0, let memory else {
            throw Error.Output
        }
        let counter = Atomic<Bool>(true)
        let resources = try repeatElement(MTLResidencySetDescriptor(), count: 2).map(device.makeResidencySet(descriptor:))
        let compiler = try device.makeCompiler(descriptor: .init())
        let rgb = try Blit.Uni(with: compiler, to: format, scale: .init(1, -1), name: "RGB2RGB")
        let yuv = try Blit.Bi(with: compiler, to: format, scale: .init(1, -1), name: "YCbCr2RGB")
        return { [cvImageBufferSubject] in
            guard case.some(let buffer) = cvImageBufferSubject.value else { return }
            let resource = switch counter.logicalXor(true, ordering: .acquiringAndReleasing) {
            case (true, false):
                resources[0]
            case (false, true):
                resources[1]
            default:
                fatalError()
            }
            resource.removeAllAllocations()
            switch CVPixelBufferGetPixelFormatType(buffer) {
            case kCVPixelFormatType_32RGBA:
                assert(!CVPixelBufferIsPlanar(buffer))
                var cvMetalTexture: CVMetalTexture?
                guard CVMetalTextureCacheCreateTextureFromImage(.none, memory, buffer, .none, .rgba8Unorm, CVPixelBufferGetWidth(buffer), CVPixelBufferGetHeight(buffer), 0, &cvMetalTexture) != kCVReturnSuccess,
                    case.some(let texture) = cvMetalTexture.flatMap(CVMetalTextureGetTexture) else { return }
                rgb.render(to: $2, with: $1, primary: texture)
                resource.addAllocation(texture)
            case kCVPixelFormatType_32BGRA:
                assert(!CVPixelBufferIsPlanar(buffer))
                var cvMetalTexture: CVMetalTexture?
                guard CVMetalTextureCacheCreateTextureFromImage(.none, memory, buffer, .none, .bgra8Unorm, CVPixelBufferGetWidth(buffer), CVPixelBufferGetHeight(buffer), 0, &cvMetalTexture) != kCVReturnSuccess,
                    case.some(let texture) = cvMetalTexture.flatMap(CVMetalTextureGetTexture) else { return }
                rgb.render(to: $2, with: $1, primary: texture)
                resource.addAllocation(texture)
            case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
                assert(CVPixelBufferIsPlanar(buffer))
                assert(CVPixelBufferGetPlaneCount(buffer) == 2)
                var Y: CVMetalTexture?
                var C: CVMetalTexture?
                guard
                    CVMetalTextureCacheCreateTextureFromImage(.none, memory, buffer, .none, .r8Unorm, CVPixelBufferGetWidthOfPlane(buffer, 0), CVPixelBufferGetHeightOfPlane(buffer, 0), 0, &Y) == kCVReturnSuccess,
                    CVMetalTextureCacheCreateTextureFromImage(.none, memory, buffer, .none, .rg8Unorm, CVPixelBufferGetWidthOfPlane(buffer, 1), CVPixelBufferGetHeightOfPlane(buffer, 1), 1, &C) == kCVReturnSuccess,
                    case.some(let Y) = Y.flatMap(CVMetalTextureGetTexture),
                    case.some(let C) = C.flatMap(CVMetalTextureGetTexture) else {
                    return
                }
                yuv.render(to: $2, with: $1, primary: Y, secondary: C)
                resource.addAllocations([Y, C])
            default:
                break
            }
            resource.commit()
            $1.useResidencySet(resource)
        }
    }
}
//extension Camera: CVImageSource {
//    @inlinable
//    public var cvImage: Optional<CVImageBuffer> {
//        avCaptureSession.isRunning ? cvImageBufferSubject.value : .none
//    }
//}
extension Camera: Publisher {
    public typealias Output = CVImageBuffer
    public typealias Failure = Never
    public func receive<S>(subscriber: S) where S : Subscriber, S.Input == Output, S.Failure == Failure {
        cvImageBufferSubject.compactMap(\.self).receive(subscriber: subscriber)
    }
}
extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        CMSampleBufferGetImageBuffer(sampleBuffer).map(cvImageBufferSubject.send)
    }
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    }
}
