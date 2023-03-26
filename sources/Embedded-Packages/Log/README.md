[![Swift](https://github.com/janodevorg/Log/actions/workflows/swift.yml/badge.svg)](https://github.com/janodevorg/Log/actions/workflows/swift.yml)

A simple log utility.

## Usage

```swift
let log = PrintLogger(label: "networking", logLevel: .trace)
log.debug("200 GET https://domain.com/api?1=2")
```

## Installation

```swift
dependencies: [
    .package(name: "Log", url: "https://github.com/janodevorg/Log.git", from: "1.0.0")
],
targets: [
    .target(
        name: "SomeTarget",
        dependencies: [
            .product(name: "Log", package: "Log")
        ],
// ...
```

## Output

```
[networking] Client.request(resource:co…: 40 · 200 GET https://randomuser.me/api/?results=1&inc=name&seed=abc
[networking]    ReportTests.testFormat():102 · 200 GET https://domain.com/api?1=2
```

- It aligns the method name to facilitate visual scanning.
- It doesn’t print useless elements in the Xcode console, like the full timestamp and project name. 
- It includes a `·` character you may use in the Xcode console to discard OS_Activity and multiline logs.
- It logs the output of [customDump](https://github.com/pointfreeco/swift-custom-dump) when the parameter is not a string. 
