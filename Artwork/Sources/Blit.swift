//
//  Blit.swift
//  MUGE
//
//  Created by Kota on 12/8/25.
//
@preconcurrency import Metal
package enum Blit {
    package struct Null: Protocol {
        @usableFromInline let state: MTLRenderPipelineState
        @usableFromInline let table: MTL4ArgumentTable
    }
    package struct Uni: Protocol {
        @usableFromInline let state: MTLRenderPipelineState
        @usableFromInline let table: MTL4ArgumentTable
    }
    package struct Bi: Protocol {
        @usableFromInline let state: MTLRenderPipelineState
        @usableFromInline let table: MTL4ArgumentTable
    }
    protocol `Protocol` {
        var state: MTLRenderPipelineState { get }
        var table: MTL4ArgumentTable { get }
    }
}
extension Blit.Null {
    package init(with compiler: MTL4Compiler, to format: MTLPixelFormat, scale: SIMD2<Float32> = .one, fragment: (String) throws -> MTL4StitchedFunctionDescriptor) throws {
        let library = try compiler.device.makeDefaultLibrary(bundle: .module)
        let descriptor = MTL4RenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = format
        descriptor.colorAttachments[0].blendingState = .disabled
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "billboard"
            
            let special = MTL4SpecializedFunctionDescriptor()
            special.functionDescriptor = basical
            special.constantValues = .some(.init())
            special.constantValues?.setConstantValue(withUnsafeBytes(of: scale, \.baseAddress.unsafelyUnwrapped), type: .float2, index: 0)
            
            descriptor.vertexFunctionDescriptor = special
        }
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "fragment0"
            descriptor.fragmentFunctionDescriptor = basical
            descriptor.fragmentStaticLinkingDescriptor?.privateFunctionDescriptors = try [fragment("view0")]
        }
        state = try compiler.makeRenderPipelineState(descriptor: descriptor)
        table = try compiler.device.makeArgumentTable(descriptor: .init())
    }
}
extension Blit.Uni {
    package init(with compiler: MTL4Compiler, to format: MTLPixelFormat, scale: SIMD2<Float32> = .one, fragment: (String) throws -> MTL4StitchedFunctionDescriptor) throws {
        let library = try compiler.device.makeDefaultLibrary(bundle: .module)
        let descriptor = MTL4RenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = format
        descriptor.colorAttachments[0].blendingState = .disabled
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "billboard"
            
            let special = MTL4SpecializedFunctionDescriptor()
            special.functionDescriptor = basical
            special.constantValues = .some(.init())
            special.constantValues?.setConstantValue(withUnsafeBytes(of: scale, \.baseAddress.unsafelyUnwrapped), type: .float2, index: 0)
            
            descriptor.vertexFunctionDescriptor = special
        }
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "fragment1"
            descriptor.fragmentFunctionDescriptor = basical
            descriptor.fragmentStaticLinkingDescriptor?.privateFunctionDescriptors = try [fragment("view1")]
        }
        state = try compiler.makeRenderPipelineState(descriptor: descriptor)
        table = try compiler.device.makeArgumentTable(descriptor: .init(maxTextureCount: 1))
    }
}
extension Blit.Bi {
    package init(with compiler: MTL4Compiler, to format: MTLPixelFormat, scale: SIMD2<Float32> = .one, fragment: (String) throws -> MTL4StitchedFunctionDescriptor) throws {
        let library = try compiler.device.makeDefaultLibrary(bundle: .module)
        let descriptor = MTL4RenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = format
        descriptor.colorAttachments[0].blendingState = .disabled
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "billboard"
            
            let special = MTL4SpecializedFunctionDescriptor()
            special.functionDescriptor = basical
            special.constantValues = .some(.init())
            special.constantValues?.setConstantValue(withUnsafeBytes(of: scale, \.baseAddress.unsafelyUnwrapped), type: .float2, index: 0)
            
            descriptor.vertexFunctionDescriptor = special
        }
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "fragment2"
            descriptor.fragmentFunctionDescriptor = basical
            descriptor.fragmentStaticLinkingDescriptor?.privateFunctionDescriptors = try [fragment("view2")]
        }
        state = try compiler.makeRenderPipelineState(descriptor: descriptor)
        table = try compiler.device.makeArgumentTable(descriptor: .init(maxTextureCount: 2))
    }
}
extension Blit.Null {
    @inlinable
    package func render(to target: MTLTexture, with mtlCommandBuffer: MTL4CommandBuffer) {
        let descriptor = MTL4RenderPassDescriptor()
        descriptor.colorAttachments[0].texture = target
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = .init()
        let encoder = mtlCommandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        encoder?.setRenderPipelineState(state)
        encoder?.setArgumentTable(table, stages: .vertex)
        encoder?.setArgumentTable(table, stages: .fragment)
        encoder?.drawPrimitives(primitiveType: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder?.endEncoding()
    }
}
extension Blit.Uni {
    @inlinable
    package func render(to target: MTLTexture, with mtlCommandBuffer: MTL4CommandBuffer, primary: MTLTexture) {
        table.setTexture(primary.gpuResourceID, index: 0)
        let descriptor = MTL4RenderPassDescriptor()
        descriptor.colorAttachments[0].texture = target
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = .init()
        let encoder = mtlCommandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        encoder?.barrier(afterQueueStages: .all, beforeStages: .fragment)
        encoder?.setRenderPipelineState(state)
        encoder?.setArgumentTable(table, stages: .vertex)
        encoder?.setArgumentTable(table, stages: .fragment)
        encoder?.drawPrimitives(primitiveType: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder?.endEncoding()
    }
}
extension Blit.Bi {
    @inlinable
    package func render(to target: MTLTexture, with mtlCommandBuffer: MTL4CommandBuffer, primary: MTLTexture, secondary: MTLTexture) {
        table.setTexture(primary.gpuResourceID, index: 0)
        table.setTexture(secondary.gpuResourceID, index: 1)
        let descriptor = MTL4RenderPassDescriptor()
        descriptor.colorAttachments[0].texture = target
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = .init()
        let encoder = mtlCommandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        encoder?.barrier(afterQueueStages: .all, beforeStages: .fragment)
        encoder?.setRenderPipelineState(state)
        encoder?.setArgumentTable(table, stages: .vertex)
        encoder?.setArgumentTable(table, stages: .fragment)
        encoder?.drawPrimitives(primitiveType: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder?.endEncoding()
    }
}
extension Blit.Null {
    package init(with compiler: MTL4Compiler, to format: MTLPixelFormat, scale: SIMD2<Float32> = .one, name: String) throws {
        let library = try compiler.device.makeDefaultLibrary(bundle: .module)
        let descriptor = MTL4RenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = format
        descriptor.colorAttachments[0].blendingState = .disabled
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "billboard"
            
            let special = MTL4SpecializedFunctionDescriptor()
            special.functionDescriptor = basical
            special.constantValues = .some(.init())
            special.constantValues?.setConstantValue(withUnsafeBytes(of: scale, \.baseAddress.unsafelyUnwrapped), type: .float2, index: 0)
            
            descriptor.vertexFunctionDescriptor = special
        }
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "fragment0"
            descriptor.fragmentFunctionDescriptor = basical
            
            let stitch = MTL4StitchedFunctionDescriptor()
            let imp = MTL4LibraryFunctionDescriptor()
            imp.library = library
            imp.name = name
            stitch.functionGraph = .some(.init(functionName: "view0",
                                               nodes: .init(),
                                               outputNode: .some(.init(name: name,
                                                                       arguments: (0..<1).map(MTLFunctionStitchingInputNode.init(argumentIndex:)),
                                                                       controlDependencies: .init())),
                                               attributes: .init()))
            stitch.functionDescriptors = [imp]
            descriptor.fragmentStaticLinkingDescriptor?.privateFunctionDescriptors = [stitch]
        }
        state = try compiler.makeRenderPipelineState(descriptor: descriptor)
        table = try compiler.device.makeArgumentTable(descriptor: .init(maxTextureCount: 0))
    }
}
extension Blit.Uni {
    package init(with compiler: MTL4Compiler, to format: MTLPixelFormat, scale: SIMD2<Float32> = .one, name: String) throws {
        let library = try compiler.device.makeDefaultLibrary(bundle: .module)
        let descriptor = MTL4RenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = format
        descriptor.colorAttachments[0].blendingState = .disabled
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "billboard"
            
            let special = MTL4SpecializedFunctionDescriptor()
            special.functionDescriptor = basical
            special.constantValues = .some(.init())
            special.constantValues?.setConstantValue(withUnsafeBytes(of: scale, \.baseAddress.unsafelyUnwrapped), type: .float2, index: 0)
            
            descriptor.vertexFunctionDescriptor = special
        }
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "fragment1"
            descriptor.fragmentFunctionDescriptor = basical
            
            let stitch = MTL4StitchedFunctionDescriptor()
            let imp = MTL4LibraryFunctionDescriptor()
            imp.library = library
            imp.name = name
            stitch.functionGraph = .some(.init(functionName: "view1",
                                               nodes: .init(),
                                               outputNode: .some(.init(name: name,
                                                                       arguments: (0..<2).map(MTLFunctionStitchingInputNode.init(argumentIndex:)),
                                                                       controlDependencies: .init())),
                                               attributes: .init()))
            stitch.functionDescriptors = [imp]
            descriptor.fragmentStaticLinkingDescriptor?.privateFunctionDescriptors = [stitch]
        }
        state = try compiler.makeRenderPipelineState(descriptor: descriptor)
        table = try compiler.device.makeArgumentTable(descriptor: .init(maxTextureCount: 1))
    }
}
extension Blit.Bi {
    package init(with compiler: MTL4Compiler, to format: MTLPixelFormat, scale: SIMD2<Float32> = .one, name: String) throws {
        let library = try compiler.device.makeDefaultLibrary(bundle: .module)
        let descriptor = MTL4RenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = format
        descriptor.colorAttachments[0].blendingState = .disabled
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "billboard"
            
            let special = MTL4SpecializedFunctionDescriptor()
            special.functionDescriptor = basical
            special.constantValues = .some(.init())
            special.constantValues?.setConstantValue(withUnsafeBytes(of: scale, \.baseAddress.unsafelyUnwrapped), type: .float2, index: 0)
            
            descriptor.vertexFunctionDescriptor = special
        }
        do {
            let basical = MTL4LibraryFunctionDescriptor()
            basical.library = library
            basical.name = "fragment2"
            descriptor.fragmentFunctionDescriptor = basical
            
            let stitch = MTL4StitchedFunctionDescriptor()
            let imp = MTL4LibraryFunctionDescriptor()
            imp.library = library
            imp.name = name
            stitch.functionGraph = .some(.init(functionName: "view2",
                                               nodes: .init(),
                                               outputNode: .some(.init(name: name,
                                                                       arguments: (0..<3).map(MTLFunctionStitchingInputNode.init(argumentIndex:)),
                                                                       controlDependencies: .init())),
                                               attributes: .init()))
            stitch.functionDescriptors = [imp]
            descriptor.fragmentStaticLinkingDescriptor?.privateFunctionDescriptors = [stitch]
        }
        state = try compiler.makeRenderPipelineState(descriptor: descriptor)
        table = try compiler.device.makeArgumentTable(descriptor: .init(maxTextureCount: 2))
    }
}
