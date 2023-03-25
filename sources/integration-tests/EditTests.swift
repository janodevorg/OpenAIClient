import OpenAIAPI
import OpenAIClient
import XCTest

final class EditTests: BaseTests {
    /// See [Create edit](https://platform.openai.com/docs/api-reference/edits/create)
    func testCreateEdit_text() async throws {
        await dumpJSONCatchingErrors {
            try await client.edit(
                request: CreateEditRequest(model: Model.davinciEdit001.id, input: "Good mroning", instruction: "Fix spelling")
            )
        }
    }

    /// See [Create edit](https://platform.openai.com/docs/api-reference/edits/create)
    func testCreateEdit_code() async throws {
        await dumpJSONCatchingErrors {
            try await client.edit(
                request: CreateEditRequest(model: Model.codeDavinciEdit001.id, input: "", instruction: "Write a hello world in Python.")
            )
        }
    }
}
