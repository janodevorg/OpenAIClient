// swift-tools-version:5.7.1
import PackageDescription

let package = Package(
    name: "OpenAIClient",
    platforms: [
        .iOS(.v13), 
        .macCatalyst(.v13), 
        .macOS(.v12),
        .tvOS(.v13)
    ],
    products: [
        .library(name: "OpenAIClient", targets: ["OpenAIClient"]),
    ],
    dependencies: [
        .package(url: "git@github.com:apple/swift-docc-plugin.git", from: "1.0.0"),
        .package(url: "git@github.com:janodevorg/OpenAIAPI.git", from: "1.0.0"),
        .package(url: "git@github.com:ProxymanApp/atlantis.git", from : "1.21.0"),
        // ↓ 'main' because there is still no version for this fix: https://github.com/realm/SwiftLint/issues/4722
        // .package(url: "git@github.com:realm/SwiftLint.git", branch: "main")
    ],
    targets: [
        .target(
            name: "OpenAIClient",
            dependencies: [
                .product(name: "OpenAIAPI", package: "OpenAIAPI")
            ],
            path: "Sources",
            exclude: [
                "Embedded-Packages/CustomDump/LICENSE.txt",
                "Embedded-Packages/CustomDump/README.md",
                "Embedded-Packages/CustomDump/VERSION-0.9.1",
                "Embedded-Packages/Log/LICENSE.txt",
                "Embedded-Packages/Log/README.md",
                "Embedded-Packages/Log/VERSION-1.0.0",
                "Embedded-Packages/MultipartEncoder/LICENSE.txt",
                "Embedded-Packages/LDSwiftEventSource/LICENSE.txt",
                "Embedded-Packages/LDSwiftEventSource/README.md",
                "Embedded-Packages/LDSwiftEventSource/VERSION-3.0.0",
                "Embedded-Packages/XCTestDynamicOverlay/LICENSE.txt",
                "Embedded-Packages/XCTestDynamicOverlay/README.md",
                "Embedded-Packages/XCTestDynamicOverlay/VERSION-0.8.4"
            ],
            plugins: [
                // disabling on release because depending on swiftlint would mark the package as unstable
                // .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
            ]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "OpenAIClient",
                .product(name: "Atlantis", package: "Atlantis")
            ],
            path: "Tests/Integration",
            resources: [
              .process("resources")
            ]
        ),
        .testTarget(
            name: "UnitTests",
            dependencies: [
                "OpenAIClient"
            ],
            path: "Tests/Unit"
        )
    ]
)
