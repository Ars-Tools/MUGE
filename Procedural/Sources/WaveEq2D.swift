//
//  WaveEq2D.swift
//  MUGE
//
//  Created by Kota on 12/10/25.
//
@preconcurrency import Artwork
import SwiftUI
import Synchronization
public struct WaveEq2D {
    @usableFromInline let size: SIMD2<Int>
    @inlinable
    public init(size: SIMD2<Int>) {
        self.size = size
    }
}
extension WaveEq2D: MTLArtwork {
    public func callAsFunction(in residency: any MTLResidencySet, signal: some Publisher<(SIMD2<Double>, any Gesture), Never>) throws -> (MTLTextureDescriptor, @Sendable (CFTimeInterval, any MTL4CommandBuffer) -> any MTLTexture) {
        let device = residency.device
        let compiler = try device.makeCompiler(descriptor: .init())
        let library = try device.makeDefaultLibrary(bundle: .module)
        let stateDescriptor = MTL4ComputePipelineDescriptor()
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "waveeq2d"
            
            let special = MTL4SpecializedFunctionDescriptor()
            special.functionDescriptor = basical
            special.constantValues = .init()
            special.constantValues?.setConstantValue(withUnsafeBytes(of: 0.997 as Float32, \.baseAddress.unsafelyUnwrapped), type: .float, index: 0)
            
            stateDescriptor.computeFunctionDescriptor = special
        }
        let state = try compiler.makeComputePipelineState(descriptor: stateDescriptor)
        
        let fieldDescriptor = MTLTextureDescriptor()
        fieldDescriptor.usage = [.shaderRead, .shaderWrite]
        fieldDescriptor.width = size.x
        fieldDescriptor.height = size.y
        fieldDescriptor.textureType = .type2DArray
        fieldDescriptor.storageMode = .shared
        fieldDescriptor.pixelFormat = .r32Float
        fieldDescriptor.usage = [.shaderRead, .shaderWrite]
        fieldDescriptor.arrayLength = 24
        let count = Atomic<Int>(.zero)
        let field = device.makeTexture(descriptor: fieldDescriptor).unsafelyUnwrapped
        let store = signal.sink {
            switch $1 {
            case is TapGesture:
                let w = Int($0.x * Float64(size.x))
                let h = Int($0.y * Float64(size.y))
                let s = field.arrayLength - 1
                let r = MTLRegionMake2D(w, h, 1, 1)
                var v = 0 as Float32
                field.getBytes(&v,
                               bytesPerRow: MemoryLayout<Float32>.stride,
                               bytesPerImage: MemoryLayout<Float32>.stride,
                               from: r,
                               mipmapLevel: 0,
                               slice: s)
                v += 64
                field.replace(region: r,
                              mipmapLevel: 0,
                              slice: s,
                              withBytes: &v,
                              bytesPerRow: MemoryLayout<Float32>.stride,
                              bytesPerImage: MemoryLayout<Float32>.stride)
            default:
                break
            }
        }
        let index = device.makeBuffer(length: MemoryLayout<UInt32>.stride * field.arrayLength, options: .storageModeShared).unsafelyUnwrapped
        
        let table = try repeatElement(MTL4ArgumentTableDescriptor(maxBufferCount: 1, maxTextureCount: 1), count: field.arrayLength).map(device.makeArgumentTable(descriptor:)).enumerated().map {
            index.contents().storeBytes(of: UInt32($0),
                                        toByteOffset: $0 * MemoryLayout<UInt32>.stride,
                                        as: UInt32.self)
            $1.setAddress(index.gpuAddress + .init($0 * MemoryLayout<UInt32>.stride), index: 0)
            $1.setTexture(field.gpuResourceID, index: 0)
            return $1
        }
        
        residency.addAllocations([field, index])
        
        let threadsPerThreadgroup = MTLSize(width: 32, height: 32, depth: 1)
        let threadgroupsPerGrid = MTLSize(width: (size.x + 31) / 32, height: (size.y + 31) / 32, depth: 1)
        
        return (fieldDescriptor, {
            let encoder = $1.makeComputeCommandEncoder()
            encoder?.setComputePipelineState(state)
            for table in table {
//                let count = count.wrappingAdd(1, ordering: .acquiringAndReleasing).oldValue % field.arrayLength
//                encoder?.barrier(afterQueueStages: [.dispatch, .fragment], beforeStages: .dispatch)
                encoder?.setArgumentTable(table)
                
                encoder?.barrier(afterQueueStages: .dispatch, beforeStages: .dispatch)
                encoder?.dispatchThreadgroups(threadgroupsPerGrid: threadgroupsPerGrid,
                                              threadsPerThreadgroup: threadsPerThreadgroup)
            }
            encoder?.endEncoding()
            return withExtendedLifetime(store) {
                field.makeTextureView(pixelFormat: .r32Float,
                                      textureType: .type2D,
                                      levels: 0..<1,
                                      slices: 0..<1,
                                      swizzle: .init(red: .red, green: .red, blue: .red, alpha: .one)).unsafelyUnwrapped
            }
        })
    }
}
