// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "BudsControl",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "BudsControl",
            targets: ["BudsControl"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "BudsControl",
            path: "BudsControl",
            exclude: [],
            swiftSettings: [
                .define("SWIFT_PACKAGE")
            ]
        )
    ]
)
