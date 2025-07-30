import OpenAIAPI
import OpenAIClient
import XCTest

final class EmbeddingsTests: BaseTests {
    /// See [Create embedding](https://platform.openai.com/docs/api-reference/embeddings/create)
    func testCreateEmbedding() async throws {
        await dumpJSONCatchingErrors {
            let input = "Traveler 001, you are off-mission. Stop your pursuit of Traveler 3468 immediately. Stand down or face repercussions."
            return try await client.createEmbedding(
                request: CreateEmbeddingRequest(model: Model.embeddingAda002.id, input: .string(input))
            )
        }
    }
}
