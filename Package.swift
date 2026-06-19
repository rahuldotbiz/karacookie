// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Karacookie",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Karacookie", targets: ["Karacookie"])
    ],
    targets: [
        .executableTarget(
            name: "Karacookie",
            path: "Sources/Karacookie",
            exclude: ["Info.plist", "Karacookie.entitlements"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
