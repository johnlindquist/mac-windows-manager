// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Mac-Windows-Manager",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Mac-Windows-Manager",
            dependencies: []),
    ]
)