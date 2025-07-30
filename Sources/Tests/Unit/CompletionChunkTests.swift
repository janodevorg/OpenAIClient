import OpenAIClient
import XCTest

final class CompletionChunkTests: XCTestCase {
    let completionChunk = """
    {
        "id": "cmpl-6wyIHAxEL7X9c3gSn3IwyRgAzH36X",
        "object": "text_completion",
        "created": 1679512813,
        "choices": [
            {
                "text": "\\n",
                "index": 0,
                "logprobs": null,
                "finish_reason": null
            }
        ],
        "model": "text-davinci-003"
    }
    """
    func testDecode() throws {
        let data = try XCTUnwrap(Data(completionChunk.utf8))
        _ = try JSONDecoder().decode(CompletionChunk.self, from: data)
    }
}
