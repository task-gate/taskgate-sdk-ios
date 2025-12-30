// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TaskGateSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "TaskGateSDK",
            targets: ["TaskGateSDK"]
        ),
    ],
    targets: [
        .target(
            name: "TaskGateSDK",
            dependencies: []
        ),
        .testTarget(
            name: "TaskGateSDKTests",
            dependencies: ["TaskGateSDK"]
        ),
    ]
)
