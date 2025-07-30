import OpenAIAPI
import OpenAIClient
import XCTest

final class AudioTests: BaseTests, @unchecked Sendable {
    /// See [Create transcription](https://platform.openai.com/docs/api-reference/audio/create)
    func testCreateTranscription() async throws {
        await dumpJSONCatchingErrors {
            let url = try XCTUnwrap(Bundle.module.url(forResource: "sorrydave", withExtension: "mp3"))
            let data = try Data(contentsOf: url)
            let file = TranscriptionFile(filename: "sorrydave.mp3", data: data, format: .mp3)
            return try await client.createTranscription(
                file: file,
                language: ISO6391.english,
                model: Model.whisper1.rawValue,
                prompt: nil,
                temperature: nil
            )
        }
    }

    /// See [Create translation](https://platform.openai.com/docs/api-reference/audio/create)
    func testCreateTranslation() async throws {
        await dumpJSONCatchingErrors {
            let url = try XCTUnwrap(Bundle.module.url(forResource: "french", withExtension: "mp3"))
            let data = try Data(contentsOf: url)
            let file = TranscriptionFile(filename: "french.mp3", data: data, format: .mp3)
            return try await client.createTranslation(
                file: file,
                model: Model.whisper1.rawValue,
                prompt: nil,
                temperature: nil
            )
        }
    }
}
