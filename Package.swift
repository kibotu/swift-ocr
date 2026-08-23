// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-ocr",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "swift-ocr", targets: ["SwiftOCR"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "SwiftOCR",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "SwiftOCRTests",
            dependencies: ["SwiftOCR"]
        )
    ]
)
