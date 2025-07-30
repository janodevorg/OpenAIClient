import ProjectDescription

let project = Project(
    name: "OpenAIClient",
    packages: [
        .package(url: "git@github.com:SimplyDanny/SwiftLintPlugins.git", from: "0.59.1"),
        .package(url: "git@github.com:apple/swift-docc-plugin.git", from: "1.4.3"),
        .package(url: "git@github.com:pointfreeco/swift-custom-dump", from: "1.3.3"),
        .package(url: "git@github.com:janodevorg/OpenAIAPI.git", from: "1.0.0")
    ],
    settings: .settings(base: [
        "SWIFT_VERSION": "6.0",
        "IPHONEOS_DEPLOYMENT_TARGET": "18.0",
        "MACOSX_DEPLOYMENT_TARGET": "15.0",
        "ENABLE_MODULE_VERIFIER": "YES"
    ]),
    targets: [
        .target(
            name: "OpenAIClient",
            destinations: [.iPhone, .mac],
            product: .framework,
            bundleId: "dev.jano.openaiclient",
            sources: ["Sources/Main/**"],
            scripts: [
                swiftlintScript()
            ],
            dependencies: [
                .package(product: "CustomDump", type: .runtime),
                .package(product: "OpenAIAPI", type: .runtime)
            ]
        ),
        .target(
            name: "IntegrationTests",
            destinations: [.iPhone, .mac],
            product: .unitTests,
            bundleId: "dev.jano.openaiclient.integrationtests",
            sources: ["Sources/Tests/Integration/**"],
            resources: [
                .process("Sources/Tests/Integration/Resources")
            ],
            dependencies: [
                .target(name: "OpenAIClient")
            ]
        ),
        .target(
            name: "UnitTests",
            destinations: [.iPhone, .mac],
            product: .unitTests,
            bundleId: "dev.jano.openaiclient.unittests",
            sources: ["Sources/Tests/Unit/**"],
            dependencies: [
                .target(name: "OpenAIClient")
            ]
        )
    ],
    schemes: [
       Scheme.scheme(
           name: "OpenAIClient",
           shared: true,
           buildAction: BuildAction.buildAction(
               targets: [TargetReference.target("OpenAIClient")]
           ),
           testAction: .targets(
               [
                   TestableTarget.testableTarget(target: TargetReference.target("IntegrationTests")),
                   TestableTarget.testableTarget(target: TargetReference.target("UnitTests"))
               ],
               configuration: .debug,
               attachDebugger: true
           )
       )
    ]
)

func swiftlintScript() -> ProjectDescription.TargetScript {
    let script = """
    #!/bin/sh

    # Check swiftlint
    command -v /opt/homebrew/bin/swiftlint >/dev/null 2>&1 || { echo >&2 "swiftlint not found at /opt/homebrew/bin/swiftlint. Aborting."; exit 1; }

    # Create a temp file
    temp_file=$(mktemp)

    # Gather all modified and staged files within the Sources directory
    git ls-files -m Sources | grep ".swift$" > "${temp_file}"
    git diff --name-only --cached Sources | grep ".swift$" >> "${temp_file}"

    # Make list of unique and sorted files
    counter=0
    for f in $(sort "${temp_file}" | uniq)
    do
        eval "export SCRIPT_INPUT_FILE_$counter=$f"
        counter=$(expr $counter + 1)
    done

    # Lint
    if [ $counter -gt 0 ]; then
        export SCRIPT_INPUT_FILE_COUNT=${counter}
        /opt/homebrew/bin/swiftlint autocorrect --use-script-input-files
    fi
    """
    return .post(script: script, name: "Swiftlint", basedOnDependencyAnalysis: false, runForInstallBuildsOnly: false, shellPath: "/bin/zsh")
}