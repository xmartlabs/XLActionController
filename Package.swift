// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "XLActionController",
        platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(name: "XLActionController", targets: ["XLActionController"])
    ],
    targets: [
        .target(
            name: "XLActionController",
            path: "Source"
        )
    ]
)
