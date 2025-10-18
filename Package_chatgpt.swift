// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EDFCatalogoSwift",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "EDFCatalogoSwift", targets: ["EDFCatalogoSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mongodb/mongo-swift-driver.git", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.60.0"),
    ],
    targets: [
        .executableTarget(
            name: "EDFCatalogoSwift",
            dependencies: [
                .product(name: "MongoSwift", package: "mongo-swift-driver"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources"
        ),
    ]
)
