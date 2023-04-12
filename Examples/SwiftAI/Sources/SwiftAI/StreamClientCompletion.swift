import ArgumentParser
import Dispatch
import Foundation
import OpenAIClient

/// Request a completion streaming with StreamClient.
struct StreamClientCompletion: AsyncParsableCommand {
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
        let model = self.model ?? "text-davinci-002"
        let maxTokens = self.maxTokens ?? 3000

        let chunkHandler: ([CompletionChunk]) throws -> Void = { [json] chunks in
            if json {
                try chunks
                    .map { try encode(encodable: $0) ?? "" }
                    .forEach { print($0) }
            } else {
                chunks
                    .map { $0.firstChoice }
                    .joined(separator: "")
                    .forEach { print($0, separator: "", terminator: "") }
            }
        }

        let streamClient = try makeClient().streamingCompletion(
            request: .init(model: model, prompt: .string(prompt), maxTokens: maxTokens),
            streamListener: chunkHandler
        )
        streamClient.start()
        while streamClient.state != .shutdown {
            try await Task.sleep(for: .milliseconds(100))
        }
        print()
    }
}
