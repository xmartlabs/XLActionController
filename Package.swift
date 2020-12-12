// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "XLActionController",
    // platforms: [.iOS("9.0")],
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
