// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TiseFormatter",
    platforms: [.macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .plugin(name: "TiseFormatterPlugin", targets: ["TiseFormatterPlugin"]),
    ],
    targets: [
        .plugin(
            name: "TiseFormatterPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "SwiftLintBinary", condition: .when(platforms: [.macOS])),
                .target(name: "SwiftFormatBinary", condition: .when(platforms: [.macOS])),
            ]
        ),
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.52.4/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "8a8095e6235a07d00f34a9e500e7568b359f6f66a249f36d12cd846017a8c6f5"
        ),
        .binaryTarget(
            name: "SwiftFormatBinary",
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.51.7/swiftformat.artifactbundle.zip",
            checksum: "644d46307c87e516b38681b7ea986e09397ff11951ee4b76607bb8369bcbe438"
        )
    ]
)
