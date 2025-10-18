// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EDFCatalogoSwift",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "EDFCatalogoSwift", targets: ["EDFCatalogoSwift"]),
        .library(name: "EDFCatalogoLib", targets: ["EDFCatalogoLib"])
    ],
    dependencies: [
        .package(url: "https://github.com/mongodb/mongo-swift-driver.git", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.60.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        // Target de librería con todo el código de la aplicación
        .target(
            name: "EDFCatalogoLib",
            dependencies: [
                .product(name: "MongoSwift", package: "mongo-swift-driver"),
                .product(name: "NIO", package: "swift-nio"),
            ],
            path: "Sources/EDFCatalogoLib",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
        // Target ejecutable solo con el punto de entrada
        .executableTarget(
            name: "EDFCatalogoSwift",
            dependencies: [
                "EDFCatalogoLib",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/EDFCatalogoSwift"
        )
    ]
)
