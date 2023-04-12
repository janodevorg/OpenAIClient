import ArgumentParser
import Dispatch
import Foundation
import OpenAIAPI
import OpenAIClient

/// Request a completion streaming with AsyncStream.
struct StreamCompletion: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract:
        """
        Requests a completion with streaming. Try this:
        SwiftAI stream-completion "write a poem about spring" --model "text-davinci-002"
        """
    )

    @Argument(help: "The phrase to complete.")
    var prompt: String

    @Option(help: "A model able to complete sentences. e.g. text-davinci-002")
    var model: String?

    @Option(help: "Number of tokens for this completion. In the new models, prompt + answer can’t exceed 4096 tokens.")
    var maxTokens: Int?

    @Flag(help: "Set to true to receive the raw answer as JSON.")
    var json = false

    func validate() throws {
        guard !prompt.isEmpty else {
            throw ValidationError("'<prompt>' is required.")
        }
    }

    mutating func run() async throws {
        let request = CreateCompletionRequest(
            model: model ?? "text-davinci-002",
            prompt: .string(prompt),
            maxTokens: maxTokens ?? 3000,
            isStream: true
        )
        let stream = try makeClient().streamingCompletion(request: request)
        for await chunks in stream {
            for chunk in chunks {
                let text = json ? try toJsonString(chunk) : toString(chunk)
                print(text, separator: "", terminator: "")
            }
        }
        print()
    }
    
    private func toJsonString(_ chunk: CompletionChunk) throws -> String {
        try encode(encodable: chunk) ?? ""
    }
    
    private func toString(_ chunk: CompletionChunk) -> String {
        chunk.firstChoice
    }
}
