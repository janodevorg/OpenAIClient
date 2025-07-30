import Foundation

// A chat fragment sent over SSE.
public struct ChatChunk: Codable, Sendable {
    public let id, object: String
    public let created: Int
    public let model: String
    public let choices: [Choice]

    public struct Choice: Codable, Sendable {
        public struct Delta: Codable, Sendable {
            public let content: String?
            public let role: String?
        }
        public let delta: Delta
        public let index: Int
        public let finishReason: String?

        public enum CodingKeys: String, CodingKey {
            case delta, index
            case finishReason = "finish_reason"
        }
    }

    // Convenience variable to extract the payload.
    public var firstChoice: String {
        choices.first?.delta.content ?? ""
    }
}
