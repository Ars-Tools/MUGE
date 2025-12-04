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
            targets: ["Artwork"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Ars-Tools/fcikernel", from: .init(0, 0, 0))
    ],
    targets: [
        .executableTarget(
            name: "Artwork-Preview",
            dependencies: ["Artwork", "CIArtwork", "Procedure"],
            path: "Artwork/Preview"
        ),
        .target(
            name: "Artwork",
            path: "Artwork/Sources"
        ),
        .target(
            name: "CIArtwork",
            dependencies: ["Artwork"],
            path: "CIArtwork/Sources"
        ),
        .target(
            name: "Procedure",
            dependencies: ["Artwork"],
            path: "Procedure/Sources"
        )
    ]
)
