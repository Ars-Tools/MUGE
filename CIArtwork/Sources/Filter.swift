//
//  Filter.swift
//  MUGE
//
//  Created by Kota on 12/9/25.
//
//public func testCustomFilter() -> some CIArtwork {
//    let url = Bundle.module.url(forResource: "ci", withExtension: "metallib").unsafelyUnwrapped
//    let data = try! Data(contentsOf: url)
//    let kernel = try! CIColorKernel(functionName: "myColor", fromMetalLibraryData: data)
//    let source = CIFilter.randomGenerator().outputImage.unsafelyUnwrapped
//    return kernel.apply(extent: source.extent, arguments: [
//        source,
//        CIVector(x: 0.1, y: 0.9)
//    ]).flatMap(\.outputImage).unsafelyUnwrapped
//}
