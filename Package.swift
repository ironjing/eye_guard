// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacEyeGuard",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "MacEyeGuard", targets: ["MacEyeGuard"])
    ],
    targets: [
        .executableTarget(
            name: "MacEyeGuard",
            path: "Sources/MacEyeGuard"
        )
    ]
)
