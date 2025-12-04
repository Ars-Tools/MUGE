//
//  Gray-Scott-WE.swift
//  MUGE
//
//  Created by Kota on 12/4/25.
//
import SwiftUI
@preconcurrency import Metal
@preconcurrency import protocol Combine.Publisher
import Artwork
import Synchronization
public struct GrayScottWE {
    let wide: Int = 1024
    let high: Int = 1024
    public init() {
    }
}
extension GrayScottWE: Artwork {
    public func callAsFunction(as format: MTLPixelFormat,
                               in residency: MTLResidencySet,
                               signal: some Publisher<(SIMD2<Float64>, Gesture), Never>) throws -> @Sendable (CFTimeInterval, MTL4CommandBuffer, MTLTexture) -> Void {
        let device = residency.device
        let compiler = try device.makeCompiler(descriptor: .init())
        let library = try compiler.device.makeDefaultLibrary(bundle: .module)
        
        // kernel 1
        let ckDescriptor = MTL4ComputePipelineDescriptor()
        do {
            let constant = MTLFunctionConstantValues()
            constant.setConstantValue(withUnsafeBytes(of: 0.04 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 0) // f
            constant.setConstantValue(withUnsafeBytes(of: 0.06 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 1) // k
//            constant.setConstantValue(withUnsafeBytes(of: 0.024 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 0) // f
//            constant.setConstantValue(withUnsafeBytes(of: 0.050 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 1) // k
//            constant.setConstantValue(withUnsafeBytes(of: 0.036 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 0) // f
//            constant.setConstantValue(withUnsafeBytes(of: 0.058 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 1) // k
//            constant.setConstantValue(withUnsafeBytes(of: 0.034 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 0) // f
//            constant.setConstantValue(withUnsafeBytes(of: 0.057 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 1) // k
//            constant.setConstantValue(withUnsafeBytes(of: 0.012 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 0) // f
//            constant.setConstantValue(withUnsafeBytes(of: 0.032 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 1) // k
            constant.setConstantValue(withUnsafeBytes(of: 2.30e-5 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 2) // Du
            constant.setConstantValue(withUnsafeBytes(of: 1.15e-5 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 3) // Dv
            constant.setConstantValue(withUnsafeBytes(of: 0.01 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 4) // dx
            constant.setConstantValue(withUnsafeBytes(of: 1.00 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 5) // dt
            
            let cs = MTL4LibraryFunctionDescriptor()
            cs.name = "gswecs"
            cs.library = library
            
            let ck = MTL4SpecializedFunctionDescriptor()
            ck.constantValues = constant
            ck.functionDescriptor = cs
            ckDescriptor.computeFunctionDescriptor = ck
            
        }
        let ck = try compiler.makeComputePipelineState(descriptor: ckDescriptor)
        
        let skDescriptor = MTL4ComputePipelineDescriptor()
        do {
            let cs = MTL4LibraryFunctionDescriptor()
            cs.name = "gswecc"
            cs.library = library
            skDescriptor.computeFunctionDescriptor = cs
        }
        let sk = try compiler.makeComputePipelineState(descriptor: skDescriptor)
        
        let rpDescriptor = MTL4RenderPipelineDescriptor()
        rpDescriptor.colorAttachments[0].pixelFormat = format
        rpDescriptor.colorAttachments[0].blendingState = .disabled
        do {
            let vsDescriptor = MTL4LibraryFunctionDescriptor()
            vsDescriptor.name = "gswevs"
            vsDescriptor.library = library
            rpDescriptor.vertexFunctionDescriptor = vsDescriptor
        }
        do {
            let fsDescriptor = MTL4LibraryFunctionDescriptor()
            fsDescriptor.name = "gswefs"
            fsDescriptor.library = library
            rpDescriptor.fragmentFunctionDescriptor = fsDescriptor
        }
        
        let rp = try compiler.makeRenderPipelineState(descriptor: rpDescriptor)
        
        let descriptor = MTLTextureDescriptor()
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.width = wide
        descriptor.height = high
        descriptor.textureType = .type2DArray
        descriptor.storageMode = .shared
        descriptor.pixelFormat = .r32Float
        descriptor.arrayLength = 6
        
        let texture = device.makeTexture(descriptor: descriptor).unsafelyUnwrapped
        texture.replace(region: .init(origin: .init(x: 256-16, y: 256-16, z: 0), size: .init(width: 64, height: 64, depth: 1)),
                        mipmapLevel: 0, slice: 0,
                        withBytes: Array<Float32>(repeating: 0.50, count: 64 * 64 * 2 * 4),
                        bytesPerRow: MemoryLayout<Float32>.stride * 64,
                        bytesPerImage: MemoryLayout<Float32>.stride * 64 * 64)
        texture.replace(region: .init(origin: .init(x: 256-16, y: 256-16, z: 0), size: .init(width: 64, height: 64, depth: 1)),
                        mipmapLevel: 0, slice: 1,
                        withBytes: Array<Float32>(repeating: 0.25, count: 64 * 64 * 2 * 4),
                        bytesPerRow: MemoryLayout<Float32>.stride * 64,
                        bytesPerImage: MemoryLayout<Float32>.stride * 64 * 64)
        residency.addAllocation(texture)
        
        let buffer = device.makeBuffer(length: MemoryLayout<SIMD2<Float32>>.stride * 4).unsafelyUnwrapped
        buffer.contents().assumingMemoryBound(to: SIMD2<Float32>.self)[0] = .init(0, 0)
        buffer.contents().assumingMemoryBound(to: SIMD2<Float32>.self)[1] = .init(0, 1)
        buffer.contents().assumingMemoryBound(to: SIMD2<Float32>.self)[2] = .init(1, 0)
        buffer.contents().assumingMemoryBound(to: SIMD2<Float32>.self)[3] = .init(1, 1)
        residency.addAllocation(buffer)
        
        let cstableDescriptor = MTL4ArgumentTableDescriptor()
        cstableDescriptor.maxTextureBindCount = 1
        let cstable = try device.makeArgumentTable(descriptor: cstableDescriptor)
        cstable.setTexture(texture.gpuResourceID, index: 0)
        
        let vstableDescriptor = MTL4ArgumentTableDescriptor()
        vstableDescriptor.maxBufferBindCount = 2
        let vstable = try device.makeArgumentTable(descriptor: vstableDescriptor)
        vstable.setAddress(buffer.gpuAddress, index: 0)
        
        let rot = device.makeBuffer(length: MemoryLayout<UInt32>.stride).unsafelyUnwrapped
        vstable.setAddress(rot.gpuAddress, index: 1)
        
        residency.addAllocation(rot)
        
        let fstableDescriptor = MTL4ArgumentTableDescriptor()
        fstableDescriptor.maxTextureBindCount = 1
        let fstable = try device.makeArgumentTable(descriptor: fstableDescriptor)
        fstable.setTexture(texture.gpuResourceID, index: 0)
        
        let cancel = signal.sink {
            let p = $0 * SIMD2<Float64>(.init(wide), .init(high))
            switch $1 {
            case is TapGesture:
                texture.replace(region: .init(origin: .init(x: .init(p.x), y: .init(p.y), z: 0),
                                              size: .init(width: 8, height: 8, depth: 1)),
                                mipmapLevel: 0, slice: 3,
                                withBytes: Array<Float32>(repeating: 1, count: 8 * 8),
                                bytesPerRow: MemoryLayout<Float32>.stride * 8,
                                bytesPerImage: MemoryLayout<Float32>.stride * 8 * 8)
            default:
                break
            }
        }
        let fence = device.makeFence().unsafelyUnwrapped
        return {
            withExtendedLifetime(cancel) {  }
//            rot.contents().storeBytes(of: idx.add(1, ordering: .acquiringAndReleasing).oldValue, as: UInt32.self)
            for fence in repeatElement(fence, count: 6) {
                do {
                    let encoder = $1.makeComputeCommandEncoder()
                    encoder?.setComputePipelineState(ck)
                    encoder?.setArgumentTable(cstable)
                    encoder?.waitForFence(fence, beforeEncoderStages: .dispatch)
                    encoder?.dispatchThreadgroups(threadgroupsPerGrid: .init(width: 32, height: 32, depth: 1),
                                                  threadsPerThreadgroup: .init(width: 32, height: 32, depth: 1))
                    encoder?.updateFence(fence, afterEncoderStages: .dispatch)
                    encoder?.endEncoding()
                }
                do {
                    let encoder = $1.makeComputeCommandEncoder()
                    encoder?.setComputePipelineState(sk)
                    encoder?.setArgumentTable(cstable)
                    encoder?.waitForFence(fence, beforeEncoderStages: .dispatch)
                    encoder?.dispatchThreadgroups(threadgroupsPerGrid: .init(width: 32, height: 32, depth: 1),
                                                  threadsPerThreadgroup: .init(width: 32, height: 32, depth: 1))
                    encoder?.updateFence(fence, afterEncoderStages: .dispatch)
                    encoder?.endEncoding()
                }
                
            }
           
            do {
                let descriptor = MTL4RenderPassDescriptor()
                descriptor.colorAttachments[0].texture = $2
                descriptor.colorAttachments[0].loadAction = .clear
                descriptor.colorAttachments[0].storeAction = .store
                descriptor.colorAttachments[0].clearColor = .init(red: 1, green: 1, blue: 1, alpha: 1)
                
                let encoder = $1.makeRenderCommandEncoder(descriptor: descriptor).unsafelyUnwrapped
                encoder.setRenderPipelineState(rp)
                encoder.setArgumentTable(vstable, stages: .vertex)
                encoder.setArgumentTable(fstable, stages: .fragment)
                encoder.drawPrimitives(primitiveType: .triangleStrip, vertexStart: 0, vertexCount: 4)
                encoder.endEncoding()
            }
            
        }
    }
}
