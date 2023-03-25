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
        .package(url: "git@github.com:janodevorg/Log.git", from: "1.0.0"),
        .package(url: "git@github.com:janodevorg/OpenAIAPI.git", from: "1.0.0"),
        .package(url: "git@github.com:ProxymanApp/atlantis.git", from : "1.21.0"),
        // ↓ 'main' because there is still no version for this fix: https://github.com/realm/SwiftLint/issues/4722
        // .package(url: "git@github.com:realm/SwiftLint.git", branch: "main")
    ],
    targets: [
        .target(
            name: "OpenAIClient",
            dependencies: [
                .product(name: "Logger", package: "Log"),
                .product(name: "OpenAIAPI", package: "OpenAIAPI")
            ],
            path: "sources/main",
            exclude: [
                "MultipartEncoder/LICENSE.txt",
                "Streaming/LDSwiftEventSource/LICENSE.txt",
                "Streaming/LDSwiftEventSource/README.md",
                "Streaming/LDSwiftEventSource/VERSION-3.0.0"
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
                .product(name: "Atlantis", package: "Atlantis"),
                .product(name: "DumpLogger", package: "Log")
            ],
            path: "sources/integration-tests",
            resources: [
              .process("resources")
            ]
        ),
        .testTarget(
            name: "UnitTests",
            dependencies: [
                "OpenAIClient",
                .product(name: "DumpLogger", package: "Log")
            ],
            path: "sources/tests"
        )
    ]
)
