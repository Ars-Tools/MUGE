//
//  GKNoise.swift
//  MUGE
//
//  Created by Kota on 12/9/25.
//
@preconcurrency import GameplayKit
import Artwork
@inlinable
func render(size: SIMD2<some FixedWidthInteger>, source: GKNoiseSource) -> CGImage {
    SKTexture(noiseMap: .init(.init(source), size: .one, origin: .zero, sampleCount: .init(clamping: size), seamless: false)).cgImage()
}
public func voronoi(size: SIMD2<some FixedWidthInteger>,
                    seed: Int32 = .random(in: Int32.min ... Int32.max),
                    frequency: Float64,
                    displacement: Float64, distanceEnabled: Bool) -> CGImage {
    render(size: size,
           source: GKVoronoiNoiseSource(frequency: frequency,
                                        displacement: displacement,
                                        distanceEnabled: distanceEnabled,
                                        seed: seed))
}
public func perlin(size: SIMD2<some FixedWidthInteger>,
                   seed: Int32 = .random(in: Int32.min ... Int32.max),
                   frequency: Float64,
                   octave: Int, persistence: Float64, lacunarity: Float64) -> CGImage {
    render(size: size,
           source: GKPerlinNoiseSource(frequency: frequency,
                                       octaveCount: octave,
                                       persistence: persistence,
                                       lacunarity: lacunarity,
                                       seed: seed))
}
