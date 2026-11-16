// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PersonalBlog",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/twostraws/Ignite.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "PersonalBlog",
            dependencies: ["Ignite"]),
        // Checks the generated site in Build/. Run `swift run` first.
        .testTarget(
            name: "SiteTests"),
    ]
)
