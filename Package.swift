// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "swift-brainfuck-interpreter",
    products: [
        .library(
            name: "Brainfuck",
            targets: ["Brainfuck"]),
        .executable(
            name: "bf",
            targets: ["BF"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Brainfuck",
            dependencies: []),
        .executableTarget(
            name: "BF",
            dependencies: [
                "Brainfuck",
                .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .testTarget(
            name: "BrainfuckTests",
            dependencies: ["Brainfuck", "BF"]),
    ]
)
