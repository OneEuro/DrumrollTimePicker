// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DrumrollTimePicker",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "DrumrollTimePicker",
            targets: ["DrumrollTimePicker"]
        ),
    ],
    targets: [
        .target(
            name: "DrumrollTimePicker",
            path: "DatePickerWithoutStoryboard",
            exclude: [
                "main.swift",
                "AppDelegate.swift",
                "Assets.xcassets",
                "DatePickerWithoutStoryboard.entitlements"
            ]
        )
    ]
)
