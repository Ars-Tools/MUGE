//
//  NBody.swift
//  MUGE
//
//  Created by Kota on 12/12/25.
//
@preconcurrency import Artwork
import Synchronization
public struct NBody2D {
    public let x: MTLBuffer
    public let y: MTLBuffer
    @usableFromInline let z: MTLBuffer
    @usableFromInline let w: MTLBuffer
    @usableFromInline let m: Int
    @usableFromInline let n: Int
}
extension NBody2D {
    public init(device: MTLDevice, object: Array<Float32>, length: Int) throws {
        m = object.count
        n = length
        x = device.makeBuffer(length: MemoryLayout<Float32>.stride * m * n, options: .storageModeShared).unsafelyUnwrapped
        y = device.makeBuffer(length: MemoryLayout<Float32>.stride * m * n, options: .storageModeShared).unsafelyUnwrapped
        z = device.makeBuffer(length: MemoryLayout<Float32>.stride * m * ( n * 2 + 1 ), options: .storageModeShared).unsafelyUnwrapped
        w = device.makeBuffer(length: MemoryLayout<UInt32>.stride * n, options: .storageModeShared).unsafelyUnwrapped
        z.contents().advanced(by: MemoryLayout<Float32>.stride * 2 * m * n).copyMemory(from: object, byteCount: MemoryLayout<Float32>.stride * object.count)
        w.contents().copyMemory(from: Array(0..<UInt32(n)), byteCount: MemoryLayout<UInt32>.stride * n)
    }
}
extension NBody2D: Artwork {
    public func callAsFunction(as format: MTLPixelFormat, in residency: MTLResidencySet, signal: some Publisher<(SIMD2<Double>, Gesture), Never>) throws -> @Sendable (CFTimeInterval, MTL4CommandBuffer, MTLTexture) -> Void {
        let device = residency.device
        let library = try device.makeDefaultLibrary(bundle: .module)
        let compiler = try device.makeCompiler(descriptor: .init())
        let constant = MTLFunctionConstantValues()
        do {
            constant.setConstantValue(withUnsafeBytes(of: UInt32(m), \.baseAddress.unsafelyUnwrapped), type: .uint, index: 0)
            constant.setConstantValue(withUnsafeBytes(of: UInt32(n), \.baseAddress.unsafelyUnwrapped), type: .uint, index: 1)
            constant.setConstantValue(withUnsafeBytes(of: Float32(1e-2), \.baseAddress.unsafelyUnwrapped), type: .float, index: 2) // dt
            constant.setConstantValue(withUnsafeBytes(of: Float32(1e-3), \.baseAddress.unsafelyUnwrapped), type: .float, index: 3) // gf
        }
        let kernelDescriptor = MTL4ComputePipelineDescriptor()
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "nbody2Dc"
            let special = MTL4SpecializedFunctionDescriptor()
            special.functionDescriptor = basical
            special.constantValues = constant
            kernelDescriptor.computeFunctionDescriptor = special
        }
        let kernel = try compiler.makeComputePipelineState(descriptor: kernelDescriptor)
        
        let renderDescriptor = MTL4RenderPipelineDescriptor()
        do {
            renderDescriptor.colorAttachments[0].pixelFormat = format
            renderDescriptor.colorAttachments[0].blendingState = .disabled
        }
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "nbody2Dv"
            let special = MTL4SpecializedFunctionDescriptor()
            special.functionDescriptor = basical
            special.constantValues = constant
            renderDescriptor.vertexFunctionDescriptor = special
        }
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "nbody2Df"
            renderDescriptor.fragmentFunctionDescriptor = basical
        }
        let render = try compiler.makeRenderPipelineState(descriptor: renderDescriptor)
        
        let argument = try device.makeArgumentTable(descriptor: .init(maxBufferCount: 6))
        argument.setAddress(x.gpuAddress, index: 0)
        argument.setAddress(y.gpuAddress, index: 1)
        argument.setAddress(z.gpuAddress + .init(MemoryLayout<Float32>.stride * (m * n * 0)), index: 3)
        argument.setAddress(z.gpuAddress + .init(MemoryLayout<Float32>.stride * (m * n * 1)), index: 4)
        argument.setAddress(z.gpuAddress + .init(MemoryLayout<Float32>.stride * (m * n * 2)), index: 5)
        
        for k in 0..<m {
            let x = x.contents().advanced(by: MemoryLayout<Float32>.stride * n * k)
            let y = y.contents().advanced(by: MemoryLayout<Float32>.stride * n * k)
            x.storeBytes(of: Float32.random(in: -1 ... 1), as: Float32.self)
            y.storeBytes(of: Float32.random(in: -1 ... 1), as: Float32.self)
            for t in 1..<n {
                x.storeBytes(of: x.load(fromByteOffset: MemoryLayout<Float32>.stride * (t-1), as: Float32.self) + Float32.random(in: -1e-2 ... 1e-2),
                             toByteOffset: MemoryLayout<Float32>.stride * t, as: Float32.self)
                y.storeBytes(of: y.load(fromByteOffset: MemoryLayout<Float32>.stride * (t-1), as: Float32.self) + Float32.random(in: -1e-2 ... 1e-2),
                             toByteOffset: MemoryLayout<Float32>.stride * t, as: Float32.self)
            }
        }
        
        residency.addAllocations([x, y, z])
        
        let count = Atomic<Int>(.zero)
        return {
            argument.setAddress(w.gpuAddress + .init(MemoryLayout<UInt32>.stride * (count.add(1, ordering: .acquiringAndReleasing).oldValue % n)), index: 2)
            do {
                let encoder = $1.makeComputeCommandEncoder()
                encoder?.barrier(afterQueueStages: .all, beforeStages: .dispatch)
                encoder?.setComputePipelineState(kernel)
                encoder?.setArgumentTable(argument)
                encoder?.dispatchThreadgroups(threadgroupsPerGrid: .init(width: (m+kernel.threadExecutionWidth-1)/kernel.threadExecutionWidth, height: 1, depth: 1),
                                              threadsPerThreadgroup: .init(width: kernel.threadExecutionWidth, height: 1, depth: 1))
                encoder?.endEncoding()
            }
            do {
                let descriptor = MTL4RenderPassDescriptor()
                descriptor.colorAttachments[0].texture = $2
                descriptor.colorAttachments[0].storeAction = .store
                descriptor.colorAttachments[0].loadAction = .clear
                descriptor.colorAttachments[0].clearColor = .init()
                let encoder = $1.makeRenderCommandEncoder(descriptor: descriptor)
                encoder?.barrier(afterQueueStages: .dispatch, beforeStages: .vertex)
                encoder?.setRenderPipelineState(render)
                encoder?.setArgumentTable(argument, stages: .vertex)
                encoder?.drawPrimitives(primitiveType: .lineStrip, vertexStart: 0, vertexCount: n, instanceCount: m)
                encoder?.endEncoding()
            }
        }
    }
}
