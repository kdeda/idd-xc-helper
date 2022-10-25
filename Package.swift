// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "idd-xcswift-helper",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "XCSwiftHelper",
            targets: ["XCSwiftHelper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kdeda/idd-swift-commons.git", from: "1.3.4")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "XCSwiftHelper",
            dependencies: [
                .product(name: "SwiftCommons", package: "idd-swift-commons")
            ]),
        .testTarget(
            name: "XCSwiftHelperTests",
            dependencies: [
                "XCSwiftHelper"
            ]),
    ]
)
