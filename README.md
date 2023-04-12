[![Swift](https://github.com/janodevorg/OpenAIAPI/actions/workflows/swift.yml/badge.svg)](https://github.com/janodevorg/OpenAIAPI/actions/workflows/swift.yml) [![MIT license](http://img.shields.io/badge/license-MIT-lightgrey.svg)](http://opensource.org/licenses/MIT)

# OpenAIClient

Swift implementation of the OpenAI API partially generated from the OpenAI definition. All features implemented.

## Installation

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "git@github.com:janodevorg/OpenAIClient.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "...",
            dependencies: [
                .product(name: "OpenAIClient", package: "OpenAIClient")
            ]
        )
    ]
)
````

## Usage

To configure the client:
```swift
let client = OpenAIClient(log: log)
client.configure(apiKey: "API_KEY", companyKey: "ORGANIZATION_ID")
```

To request a completion:
```swift
let prompt = "hello there chatgpt!"
let response = try await client.completions(request: .init(model: Model.davinci003.id, prompt: .string(prompt)))
print("response: \(response.choices.first?.text)")
```

To request a streaming completion:
```swift
let prompt = "hello there chatgpt!"
let streamClient = try client.streamingChatCompletion(
    streamListener: { print("chunk \($0)") },
    modelId: Model.gpt35turbo.id,
    conversation: [ChatCompletionRequestMessage(role: .user, content: prompt)]
)
streamClient.start()
```
Call `stop()` to stop streaming or wait until `streamClient.state == .shutdown`.

To request a streaming completion as an AsyncStream:
```swift
let request = CreateCompletionRequest(
    model: Model.davinci002.id,
    prompt: .string("hello there chatgpt!")
)
let stream = try client.streamingCompletion(request: request)
for await chunk in stream {
    print(chunk.map { $0.firstChoice }.joined())
}
```

## Example

Check [Examples/SwiftAI](https://github.com/janodevorg/OpenAIClient/tree/main/Examples/SwiftAI) for a CLI tool that uses [swift-argument-parser](https://github.com/apple/swift-argument-parser). I only implemented completion and streaming completion but it was quite easy –now I’m wondering if I should go on or ask ChatGPT to do it.

## Integration tests

The folder sources/integration-tests contains tests that make network calls. They are disabled by default because they need valid credentials and may alter data in your organization. I suggest you run them manually for debugging or to see this library in action.

To input your credentials run `make credentials` in the terminal. The resulting file will be ignored by `.gitignore`.

## Links of interest

OpenAI
- [OpenAI API docs](https://beta.openai.com/docs/api-reference/introduction)
- [The OpenAI OpenAPI definition](https://github.com/openai/openai-openapi)

Code used in this library
- [CreateAPI](https://github.com/CreateAPI/CreateAPI) - Code generator for OpenAPI definitions.
- [Get](https://github.com/kean/Get) - Network client used in the generated package.
- [LDSwiftEventSource](https://github.com/launchdarkly/swift-eventsource) A Server Side Events client.
- [Log](https://github.com/janodevorg/OpenAIAPI) - A minimal log utility.
- [MultipartFormEncoder](https://gist.github.com/samsonjs/513ef76d3e324a66ec583b2df4329cd4) - MultipartFormEncoder by Sami Samhuri.
- [OpenAIAPI](https://github.com/janodevorg/OpenAIAPI) - A Swift network client generated from the OpenAI OpenAPI definition.
