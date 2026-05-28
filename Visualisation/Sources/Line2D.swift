//
//  Lines.swift
//  MUGE
//
//  Created by Kota on 12/12/25.
//
@preconcurrency import Artwork
import Synchronization
public protocol Line2DArtwork {
    @inlinable
    func callAsFunction() -> ()
}
public struct Line2D {
    
}
extension Line2D: Artwork {
    public func callAsFunction(as format: MTLPixelFormat, in residency: any MTLResidencySet, signal: some Publisher<(SIMD2<Double>, any Gesture), Never>) throws -> @Sendable (CFTimeInterval, MTL4CommandBuffer, MTLTexture) -> Void {
        let N = 1024
        let M = 16
        let device = residency.device
        let library = try device.makeDefaultLibrary(bundle: .module)
        let compiler = try device.makeCompiler(descriptor: .init())
        let stateDescriptor = MTL4RenderPipelineDescriptor()
        stateDescriptor.colorAttachments[0].pixelFormat = format
        stateDescriptor.colorAttachments[0].blendingState = .disabled
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.name = "line2dvs"
            basical.library = library
            let special = MTL4SpecializedFunctionDescriptor()
            special.functionDescriptor = basical
            special.constantValues = .some(.init())
            special.constantValues?.setConstantValue(withUnsafeBytes(of: UInt32(N), \.baseAddress.unsafelyUnwrapped), type: .uint, index: 0)
            stateDescriptor.vertexFunctionDescriptor = special
        }
        do {
            let descriptor = MTL4LibraryFunctionDescriptor()
            descriptor.name = "line2dfs"
            descriptor.library = library
            stateDescriptor.fragmentFunctionDescriptor = descriptor
        }
        let length = MemoryLayout<Float32>.stride * 2 * M * N + MemoryLayout<UInt32>.stride
        let memory = device.makeBuffer(length: length, options: .storageModeShared)
        let state = try compiler.makeRenderPipelineState(descriptor: stateDescriptor)
        let table = try device.makeArgumentTable(descriptor: .init(maxBufferCount: 3))
        
        
        
        return {
            let descriptor = MTL4RenderPassDescriptor()
            descriptor.colorAttachments[0].texture = $2
            descriptor.colorAttachments[0].storeAction = .store
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].clearColor = .init()
            let encoder = $1.makeRenderCommandEncoder(descriptor: descriptor)
            encoder?.setRenderPipelineState(state)
            encoder?.setArgumentTable(table, stages: .vertex)
            encoder?.drawPrimitives(primitiveType: .lineStrip, vertexStart: 0, vertexCount: N, instanceCount: M)
            encoder?.endEncoding()
        }
    }
}
