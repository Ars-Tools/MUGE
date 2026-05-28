//
//  Coordinator.swift
//  MUGE
//
//  Created by Kota on 12/3/25.
//
@preconcurrency import SwiftUI
@preconcurrency import Metal
@preconcurrency import typealias Combine.PassthroughSubject
@usableFromInline
final class Coordinator: Sendable {
    @usableFromInline let screen: CAMetalLayer
    @usableFromInline let allocators: Array<MTL4CommandAllocator>
    @usableFromInline let buffer: MTL4CommandBuffer
    @usableFromInline let queue: MTL4CommandQueue
    @usableFromInline let signal: PassthroughSubject<(SIMD2<Float64>, Gesture), Never>
    @usableFromInline let kernel: @Sendable (CFTimeInterval, MTL4CommandBuffer, MTLTexture) -> Void
    init(artwork: Artwork) throws {
        enum Error: Swift.Error {
            case noDevice
            case noBuffer
        }
        signal = .init()
        screen = .init()
        screen.framebufferOnly = false
        screen.device = screen.preferredDevice ?? MTLCreateSystemDefaultDevice()
        kernel = try artwork(as: screen.pixelFormat, in: screen.residencySet, signal: signal)
        screen.residencySet.commit()
        guard case.some(let device) = screen.device else {
            throw Error.noDevice
        }
        queue = try device.makeMTL4CommandQueue(descriptor: .init())
        queue.addResidencySet(screen.residencySet)
        buffer = switch device.makeCommandBuffer() {
        case.some(let buffer):
            buffer
        case.none:
            throw Error.noBuffer
        }
        allocators = try repeatElement(MTL4CommandAllocatorDescriptor(), count: screen.maximumDrawableCount).map(device.makeCommandAllocator(descriptor:))
    }
}
extension Coordinator: CAMetalDisplayLinkDelegate {
    @inlinable
    func metalDisplayLink(_ link: CAMetalDisplayLink, needsUpdate update: CAMetalDisplayLink.Update) {
        let allocator = allocators[update.drawable.drawableID % allocators.count]
        allocator.reset()
        
        buffer.beginCommandBuffer(allocator: allocator)
        kernel(update.targetPresentationTimestamp, buffer, update.drawable.texture)
        buffer.endCommandBuffer()
        //
        queue.waitForDrawable(update.drawable)
        queue.commit([buffer])
        queue.signalDrawable(update.drawable)
        //
        update.drawable.present()
    }
}
extension Coordinator {
    @inlinable
    var displaylink: CAMetalDisplayLink {
        let displaylink = CAMetalDisplayLink.init(metalLayer: screen)
        defer {
            displaylink.delegate = self // weak ref
        }
        return displaylink
    }
}
