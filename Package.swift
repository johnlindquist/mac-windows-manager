// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "mwm",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "mwm",
            dependencies: [],
            path: "Sources"
        ),
    ]
)