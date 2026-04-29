// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ChefItKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "ChefItKit", targets: ["ChefItKit"])
    ],
    targets: [
        .target(
            name: "ChefItKit",
            path: "Sources/ChefItKit"
        ),
        .testTarget(
            name: "ChefItKitTests",
            dependencies: ["ChefItKit"],
            path: "Tests/ChefItKitTests"
        )
    ]
)
