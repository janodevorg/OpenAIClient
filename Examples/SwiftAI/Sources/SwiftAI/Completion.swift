import ArgumentParser
import Dispatch
import Foundation
import OpenAIClient

/// Request a completion.
struct Completion: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract:
        """
        Requests a completion. Try this:
        SwiftAI completion "will humans self destruct?" --model "text-davinci-002"
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

        let completion = try await makeClient().completions(request:
                .init(model: model, prompt: .string(prompt), maxTokens: maxTokens)
        )

        let noChoices = "Server didn’t return a completion for this prompt."
        let text = json
                ? try encode(encodable: completion) ?? "Failed to encode as UTF-8 string."
                : completion.choices.first?.text ?? noChoices

        print(text)
    }
}
