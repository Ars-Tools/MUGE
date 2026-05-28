//
//  Screen.swift
//  MUGE
//
//  Created by Kota on 12/7/25.
//
@preconcurrency import Metal
@preconcurrency import protocol Combine.Publisher
import Artwork
public struct Screen {
    public init() {}
}
extension Screen: Artwork {
    public func callAsFunction(as format: MTLPixelFormat, in residency: any MTLResidencySet, signal: some Publisher<(SIMD2<Double>, any Gesture), Never>) throws -> @Sendable (CFTimeInterval, any MTL4CommandBuffer, any MTLTexture) -> Void {
        let device = residency.device
        let compiler = try device.makeCompiler(descriptor: .init())
        let library = try device.makeDefaultLibrary(bundle: .module)
        let vs = MTL4LibraryFunctionDescriptor()
        do {
            vs.library = library
            vs.name = "board"
        }
        let fs = MTL4LibraryFunctionDescriptor()
        do {
            fs.library = library
            fs.name = "sponge2"
        }
        let sdfSphere = MTL4LibraryFunctionDescriptor()
        do {
            sdfSphere.library = library
            sdfSphere.name = "sdfSphere"
        }
        
        
        let gn = MTL4StitchedFunctionDescriptor()
        do {
            gn.functionDescriptors = .some([
                fs
            ])
        }
        let rp = MTL4RenderPipelineDescriptor()
        do {
            rp.colorAttachments[0].blendingState = .disabled
            rp.colorAttachments[0].pixelFormat = format
            rp.vertexFunctionDescriptor = vs
            rp.fragmentFunctionDescriptor = fs
        }
        let pipeline = try compiler.makeRenderPipelineState(descriptor: rp)
        let elapse = device.makeBuffer(length: MemoryLayout<Float32>.size).unsafelyUnwrapped
        residency.addAllocation(elapse)
        
        let descriptor = MTL4ArgumentTableDescriptor()
        descriptor.maxBufferBindCount = 2
        let arguments = try device.makeArgumentTable(descriptor: descriptor)
        arguments.setAddress(elapse.gpuAddress, index: 0)
        
        
        
        
        return {
            elapse.contents().storeBytes(of: Float32(fmod($0, 3600)), as: Float32.self)
            
            let descriptor = MTL4RenderPassDescriptor()
            descriptor.colorAttachments[0].clearColor = .init()
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].storeAction = .store
            descriptor.colorAttachments[0].texture = $2
            
            let encoder = $1.makeRenderCommandEncoder(descriptor: descriptor)
            encoder?.setRenderPipelineState(pipeline)
            encoder?.setArgumentTable(arguments, stages: .fragment)
            encoder?.drawPrimitives(primitiveType: .triangleStrip, vertexStart: 0, vertexCount: 4)
            encoder?.endEncoding()
            
        }
    }
}
