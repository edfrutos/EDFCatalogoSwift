// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "EDFCatalogoSwift",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "EDFCatalogoSwift", targets: ["EDFCatalogoSwift"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "EDFCatalogoSwift",
            dependencies: [],
            path: "Sources"
        )
    ]
)
