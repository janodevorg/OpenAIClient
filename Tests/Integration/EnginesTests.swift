import OpenAIAPI
import OpenAIClient
import XCTest

final class EnginesTests: BaseTests {
    /// See [List Engines](https://platform.openai.com/docs/api-reference/engines/list).
    @available(*, deprecated, message: "Deprecated")
    func testEngines() async throws {
        await dumpJSONCatchingErrors {
            try await client.engines().data
        }
    }

    /// See [Retrieve Engine](https://platform.openai.com/docs/api-reference/engines/retrieve).
    @available(*, deprecated, message: "Deprecated")
    func testEngine() async throws {
        await dumpJSONCatchingErrors {
            try await client.engine(id: Model.gpt35turbo.id)
        }
    }
}
