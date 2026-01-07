//
//  App.swift
//  MUGE
//
//  Created by Kota on 12/3/25.
//
import SwiftUI
import Artwork
import AVArtwork
import CIArtwork
import CGArtwork
import Procedural
import CoreImage.CIFilterBuiltins
@main
struct App: SwiftUI.App {
    @State var elapse = 0.0 as Float64
    
//    let obj: CGImage = voronoi(size: .init(1024, 1024), frequency: 8, displacement: 1, distanceEnabled: false)
    @inlinable
    var body: some Scene {
        WindowGroup {
//            Image(nsImage: genNS())
//            try!Exhibit(artwork: Camera(device: .default(for: .video).unsafelyUnwrapped))
//            Exhibit(artwork: CIFilter.randomGenerator())
//            Exhibit(artwork: GrayScottWE())
//            Exhibit(artwork: perlin(size: .init(512, 512), frequency: 8, octave: 4, persistence: 0, lacunarity: 0))
//            Exhibit(artwork: obj)
//            Exhibit(artwork: testCustomFilter())
//            Exhibit(artwork: Stitch())
//            Exhibit(artwork: Raymarch())
//            Exhibit(artwork: Billboard.Screen())
//            Exhibit(artwork: WaveEq2D(size: .init(256, 256)))
//            try!Exhibit(artwork: NBody2D(device: MTLCreateSystemDefaultDevice().unsafelyUnwrapped,
//                                         object: repeatElement(0.1 ... 1.0, count: 64).map(Float32.random(in:)),
//                                         length: 1024))
            try!Exhibit(artwork: Visualise.AxesXY())
            
        }
    }
}
func genCI() -> CIImage {
    let img = CIFilter.checkerboardGenerator()
    img.setDefaults()
    return img.outputImage.unsafelyUnwrapped.cropped(to: .init(x: 0, y: 0, width: 512, height: 512))
}
//func genUI() -> UIImage {
//    let img = UIImage()
//    return img.withRenderingMode(.alwaysOriginal)
//}
func genNS() -> NSImage {
    let img = NSImage()
    
    img.size = .init(width: 512, height: 512)
    img.addRepresentation(NSCIImageRep(ciImage: genCI()))
    return img
}

@preconcurrency import Metal
@preconcurrency import protocol Combine.Publisher
import protocol SwiftUI.Gesture
import protocol Artwork.Artwork
import CoreImage.CIFilterBuiltins
public enum Visualise {}
extension Visualise {
    public struct AxesXY {
        @usableFromInline
        let x: Dictionary<Float32, Optional<(Float32, String)>>
        @usableFromInline
        let y: Dictionary<Float32, Optional<(Float32, String)>>
    }
}
extension Visualise.AxesXY {
    public init() {
        x = [:]
        y = [:]
    }
}
extension Visualise.AxesXY: `2DArtwork` {
    public var colour: MTLClearColor {
        .init(red: 0, green: 0, blue: 1, alpha: 1)
    }
    public func callAsFunction(as format: MTLPixelFormat, in residency: any MTLResidencySet, signal: some Publisher<(SIMD2<Double>, any Gesture), Never>) throws -> @Sendable (CFTimeInterval, any MTL4RenderCommandEncoder) -> Void {
        let device = residency.device
        let library = try device.makeDefaultLibrary(bundle: .module)
        let compiler = try device.makeCompiler(descriptor: .init())
        let xaxisDescriptor = MTL4MeshRenderPipelineDescriptor()
        xaxisDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            let mesh = MTL4LibraryFunctionDescriptor()
            mesh.library = library
            mesh.name = "xaxis"
            xaxisDescriptor.meshFunctionDescriptor = mesh
            
            let frag = MTL4LibraryFunctionDescriptor()
            frag.library = library
            frag.name = "white"
            xaxisDescriptor.fragmentFunctionDescriptor = frag
        }
        let yaxisDescriptor = MTL4MeshRenderPipelineDescriptor()
        yaxisDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            let mesh = MTL4LibraryFunctionDescriptor()
            mesh.library = library
            mesh.name = "yaxis"
            yaxisDescriptor.meshFunctionDescriptor = mesh
            
            let frag = MTL4LibraryFunctionDescriptor()
            frag.library = library
            frag.name = "white"
            yaxisDescriptor.fragmentFunctionDescriptor = frag
        }
        let xk = try compiler.makeRenderPipelineState(descriptor: xaxisDescriptor)
        
        let xb = device.makeBuffer(length: MemoryLayout<Float32>.stride * 64 + MemoryLayout<UInt32>.size, options: .storageModeShared).unsafelyUnwrapped
        for k in 0..<64 {
            xb.contents().storeBytes(of: Float32(k) / 64.0, toByteOffset: MemoryLayout<Float32>.stride * k, as: Float32.self)
        }
        xb.contents().storeBytes(of: 64 as UInt32, toByteOffset: MemoryLayout<Float32>.stride * 64, as: UInt32.self)
        
        let argDescriptor = MTL4ArgumentTableDescriptor()
        argDescriptor.maxBufferBindCount = 2
        let xc = try device.makeArgumentTable(descriptor: argDescriptor)
        xc.setAddress(xb.gpuAddress, index: 0)
        xc.setAddress(xb.gpuAddress + .init(64 * MemoryLayout<Float32>.stride), index: 1)
        
        residency.addAllocation(xb)
        
        return {
            $1.setRenderPipelineState(xk)
            $1.setArgumentTable(xc, stages: .mesh)
            $1.drawMeshThreadgroups(threadgroupsPerGrid: .init(width: 1, height: 1, depth: 1),
                                          threadsPerObjectThreadgroup: .init(width: 1, height: 1, depth: 1),
                                          threadsPerMeshThreadgroup: .init(width: 64, height: 1, depth: 1))
        }
    }
}
