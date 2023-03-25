import OpenAIAPI
import OpenAIClient
import XCTest

final class ModelTests: BaseTests {
    /// See [List Models](https://platform.openai.com/docs/api-reference/models/list).
    func testModels() async throws {
        await dumpJSONCatchingErrors {
            try await client.models().data
        }
    }

    /// See [Retrieve Model](https://platform.openai.com/docs/api-reference/models/retrieve).
    func testModel() async throws {
        await dumpJSONCatchingErrors {
            try await client.model(id: Model.gpt35turbo.id)
        }
    }
}
