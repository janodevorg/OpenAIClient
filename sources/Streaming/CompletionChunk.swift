import Foundation

// A completions fragment sent over SSE.
public struct CompletionChunk: Codable {
    public struct Choice: Codable {
        public let text: String
        public let index: Int
        public let logprobs: Double?
        public let finishReason: String?
        public enum CodingKeys: String, CodingKey {
            case text, index, logprobs
            case finishReason = "finish_reason"
        }
    }
    public let id: String
    public let object: String
    public let created: Int
    public let choices: [Choice]
    public let model: String

    // Convenience variable to extract the payload.
    public var firstChoice: String {
        choices.first?.text ?? ""
    }
}
