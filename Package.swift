// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MUGE",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
    ],
    products: [
        .library(
            name: "MUGE.Artwork",
            targets: ["Artwork", "AVArtwork", "CIArtwork", "CGArtwork"]
        ),
        .library(
            name: "MUGE.Procedural",
            targets: ["Procedural"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Ars-Tools/fcikernel", from: .init(0, 0, 1))
    ],
    targets: [
        .executableTarget(
            name: "Artwork-Preview",
            dependencies: ["Artwork", "AVArtwork", "CIArtwork", "CGArtwork", "Procedural"],
            path: "Artwork/Preview"
        ),
        .target(
            name: "Artwork",
            path: "Artwork/Sources"
        ),
        .target(
            name: "AVArtwork",
            dependencies: ["Artwork", "CIArtwork"],
            path: "AVArtwork/Sources"
        ),
        .target(
            name: "CIArtwork",
            dependencies: ["Artwork"],
            path: "CIArtwork/Sources",
            plugins: [.plugin(name: "ci.metal", package: "fcikernel")]
        ),
        .target(
            name: "CGArtwork",
            dependencies: ["Artwork", "CIArtwork"],
            path: "CGArtwork/Sources"
        ),
        .target(
            name: "Procedural",
            dependencies: ["Artwork"],
            path: "Procedural/Sources"
        )
    ]
)
