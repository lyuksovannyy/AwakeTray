// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AwakeTray",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "AwakeTray", path: "Sources/AwakeTray"),
    ]
)
