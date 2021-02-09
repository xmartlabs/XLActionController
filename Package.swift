// swift-tools-version:5.3

import PackageDescription

func getExampleTarget(name: String) -> Target {
    return .target(name: "XLActionController_" + name,
                   path: "Example/CustomActionControllers",
                   dependencies: [Target.Dependency.target(name: "XLActionController")],
                   sources: ["\(name).swift", "ActionData.swift"],
                   resources: ["\(name).xib"])
}

let package = Package(
    name: "XLActionController",
        platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(name: "XLActionController", targets: ["XLActionController"]),
        .library(name: "XLActionController", targets: ["XLActionController_Skype"]),
        .library(name: "XLActionController", targets: ["XLActionController_Spotify"])
    ],
    targets: [
        .target(name: "XLActionController", path: "Source"),
        getExampleTarget(name: "Skype"),
        getExampleTarget(name: "Spotify"),        
    ]
)
