// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DeepSeekPeak",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "DeepSeekPeak",
            path: "Sources/DeepSeekPeak"
        )
    ]
)
