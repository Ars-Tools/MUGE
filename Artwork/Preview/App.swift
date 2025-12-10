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
            Exhibit(artwork: WaveEq2D(size: .init(256, 256)))
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
