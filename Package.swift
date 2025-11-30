// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "idd-xc-helper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "IDDXCHelper",
            targets: ["IDDXCHelper"]),
    ],
    dependencies: [
        // .package(name: "idd-softwareupdate", path: "../idd-softwareupdate"),
        .package(url: "https://github.com/kdeda/idd-softwareupdate.git", from: "2.1.3")
    ],
    targets: [
        .target(
            name: "IDDXCHelper",
            dependencies: [
                .product(name: "IDDSoftwareUpdate", package: "idd-softwareupdate")
            ]),
        .testTarget(
            name: "IDDXCHelperTests",
            dependencies: [
                "IDDXCHelper"
            ]),
    ]
)
