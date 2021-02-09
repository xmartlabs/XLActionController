// swift-tools-version:5.3

import PackageDescription

func getExampleTarget(name: String) -> Target {
    return .target(name: "XLActionController_" + name,
                   dependencies: [Target.Dependency.target(name: "XLActionController")],
                   path: "Example/CustomActionControllers/\(name)",
                   sources: ["\(name).swift"],
                   resources: [Resource.process("\(name)Cell.xib")],
                   swiftSettings: [SwiftSetting.define("IMPORT_BASE_XLACTIONCONTROLLER")])
}

let package = Package(
    name: "XLActionController",
        platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(name: "XLActionController", targets: ["XLActionController"]),
        .library(name: "XLActionControllerSkype", targets: ["XLActionController_Skype"]),
        .library(name: "XLActionControllerPeriscope", targets: ["XLActionController_Periscope"]),
        .library(name: "XLActionControllerSpotify", targets: ["XLActionController_Spotify"]),
        .library(name: "XLActionControllerTweetbot", targets: ["XLActionController_Tweetbot"]),
        .library(name: "XLActionControllerTwitter", targets: ["XLActionController_Twitter"]),
        .library(name: "XLActionControllerYoutube", targets: ["XLActionController_Youtube"])
    ],
    targets: [
        .target(name: "XLActionController", path: "Source",
                resources: [Resource.process("Resource/ActionCell.xib")]),
        getExampleTarget(name: "Periscope"),
        getExampleTarget(name: "Skype"),
        getExampleTarget(name: "Spotify"),
        getExampleTarget(name: "Tweetbot"),
        getExampleTarget(name: "Twitter"),
        getExampleTarget(name: "Youtube"),
    ]
)
