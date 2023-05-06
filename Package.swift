// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "idd-xc-helper",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "IDDXCHelper",
            targets: ["IDDXCHelper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kdeda/idd-swift.git", from: "2.0.4")
    ],
    targets: [
        .target(
            name: "IDDXCHelper",
            dependencies: [
                .product(name: "IDDSwift", package: "idd-swift")
            ]),
        .testTarget(
            name: "IDDXCHelperTests",
            dependencies: [
                "IDDXCHelper"
            ]),
    ]
)
