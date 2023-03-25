import OpenAIAPI
import OpenAIClient
import XCTest

final class FileTests: BaseTests {

//    // ⚠️ Remove all files for clean up
//    func testDeleteAllFiles() async throws {
//        for file in try await client.files().data {
//            do {
//                let deleteInfo = try await self.client.deleteFile(id: file.id)
//                log.debug(deleteInfo)
//            } catch {
//                log.error("\(error)")
//            }
//        }
//    }

    // {"prompt": "<prompt text>", "completion": "<ideal generated text>"}
    let fileContent = """
    {"prompt": "Why do people like soccer?", "completion": "It dispenses joy and misery at random. mimics life."}
    """

    /// See [List files](https://platform.openai.com/docs/api-reference/files/list)
    func testFiles() async throws {
        await dumpJSONCatchingErrors {
            try await client.files()
        }
    }

    /// Repeated calls to this endpoint create a file with the same name but different ID.
    /// See [Upload file](https://platform.openai.com/docs/api-reference/files/upload)
    func testUploadFile() async throws {
        await dumpJSONCatchingErrors {
            try await client.uploadFile(
                fileContent: fileContent,
                filename: "dialog-1.jsonl",
                purpose: "fine-tune"
            )
        }
    }

    /// See [Delete file](https://platform.openai.com/docs/api-reference/files/delete)
    func testDeleteFile() async throws {
        do {

            // when I upload a file and remove it
            let uploadedFile = try await client.uploadFile(
                fileContent: fileContent,
                filename: "testDeleteFile.jsonl",
                purpose: "fine-tune"
            )
            let deleteInfo = try await self.client.deleteFile(id: uploadedFile.id)
            XCTAssertTrue(deleteInfo.deleted)

        } catch {

            // failing with "file still in processing" is not an error
            if case let APIError.apiServerOpenAIError(openAIError, httpCode: httpCode) = error,
                openAIError.error.message == "File is still processing. Check back later.",
                httpCode == 409 {
                return
            }

            XCTFail("Unexpected error: \(error)")
        }
    }

    /// See [Retrieve file](https://platform.openai.com/docs/api-reference/files/retrieve)
    func testRetrieveFileInformation() async throws {
        await dumpJSONCatchingErrors {

            // when I upload a file
            let file = try await client.uploadFile(
                fileContent: fileContent,
                filename: "testRetrieveFileInformation.jsonl",
                purpose: "fine-tune"
            )

            // I can read its file information immediately
            return try await self.client.retrieveFileInformation(id: file.id)
        }
    }

    /// See [Retrieve file content](https://platform.openai.com/docs/api-reference/files/retrieve-content)
    func testRetrieveFileContent() async throws {
        await dumpJSONCatchingErrors {

            // when I upload a file
            let file = try await client.uploadFile(
                fileContent: fileContent,
                filename: "testRetrieveFileContent.jsonl",
                purpose: "fine-tune"
            )

            // I can read its contents immediately
            return try await self.client.retrieveFileContent(id: file.id)
        }
    }
}
