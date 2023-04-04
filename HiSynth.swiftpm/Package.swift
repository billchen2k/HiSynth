// swift-tools-version: 5.6

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "HiSynth",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "HiSynth",
            targets: ["AppModule"],
            bundleIdentifier: "io.billc.HiSynth",
            teamIdentifier: "7P6FX59VQB",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.teal),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/AudioKit/Keyboard", "1.0.0"..<"2.0.0"),
        .package(url: "https://github.com/AudioKit/SoundpipeAudioKit", "5.0.0"..<"6.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "Keyboard", package: "keyboard"),
                .product(name: "SoundpipeAudioKit", package: "soundpipeaudiokit")
            ],
            path: ".",
            resources: [
                .process("Resources")
            ]
        )
    ]
)