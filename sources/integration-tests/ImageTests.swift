import DumpLogger
import OpenAIAPI
import OpenAIClient
import XCTest

final class ImageTests: BaseTests {
    /// See [Create image](https://platform.openai.com/docs/api-reference/images/create)
    func testCreateImage() async throws {
        await dumpJSONCatchingErrors {
            try await client.image(
                request: CreateImageRequest(prompt: "a duck")
            )
        }
    }

    /// See [Create image edit](https://platform.openai.com/docs/api-reference/images/create-edit)
    func testCreateImageEdit() async throws {
        await dumpJSONCatchingErrors {
            try await client.imageEdit(
                prompt: "clouds",
                image: try XCTUnwrap(image),
                mask: try XCTUnwrap(mask)
            )
        }
    }

    /// See [Create image variation](https://platform.openai.com/docs/api-reference/images/create-variation)
    func testCreateImageVariation() async throws {
        await dumpJSONCatchingErrors {
            let baseImage = try XCTUnwrap(image)
            return try await client.imageVariations(image: baseImage, numberOfImages: 1)
        }
    }
}
