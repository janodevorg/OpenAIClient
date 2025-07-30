// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "OpenAIClient",
    platforms: [
        .iOS(.v18), 
        .macCatalyst(.v18), 
        .macOS(.v15),
        .tvOS(.v18)
    ],
    products: [
        .library(name: "OpenAIClient", targets: ["OpenAIClient"]),
    ],
    dependencies: [
        .package(url: "git@github.com:pointfreeco/swift-custom-dump", from: "1.3.3"),
        .package(url: "git@github.com:apple/swift-docc-plugin.git", from: "1.4.3"),
        .package(url: "git@github.com:janodevorg/OpenAIAPI.git", from: "1.0.0")
        // disabled because it creates problems building release versions: Missing package product 'SwiftLintPlugin@11'
//        .package(url: "git@github.com:realm/SwiftLint.git", from: "0.51.0")
    ],
    targets: [
        .target(
            name: "OpenAIClient",
            dependencies: [
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "OpenAIAPI", package: "OpenAIAPI")
            ],
            path: "Sources/Main",
            exclude: [
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
            ]
//            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "OpenAIClient"
            ],
            path: "Sources/Tests/Integration",
            resources: [
              .process("Resources")
            ]
        ),
        .testTarget(
            name: "UnitTests",
            dependencies: [
                "OpenAIClient"
            ],
            path: "Sources/Tests/Unit"
        )
    ]
)
