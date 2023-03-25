import OpenAIAPI
import OpenAIClient
import XCTest

final class ModerationTests: BaseTests {
    /// See [Create moderation](https://platform.openai.com/docs/api-reference/moderations/create)
    func testCreateModeration() async throws {
        await dumpJSONCatchingErrors {
            try await client.moderation(
                input: "I’m going to find and I’m going to kill every last one of them.",
                modelId: Model.moderationLatest.id
            )
        }
    }
}
