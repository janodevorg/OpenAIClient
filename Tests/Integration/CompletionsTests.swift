import OpenAIAPI
@testable import OpenAIClient
import XCTest

final class CompletionsTests: BaseTests {
    /// See [Create completion](https://platform.openai.com/docs/api-reference/completions/create)
    func testCompletions() async throws {
        await dumpJSONCatchingErrors {
            try await client.completions(
                request: .init(model: Model.davinci003.id, prompt: .string(isTheWaterWetYesOrNo))
            )
        }
    }

    /// See [Create chat completion](https://platform.openai.com/docs/api-reference/chat/create)
    func testStreamingCompletion_asyncStream() async throws {
        let request = CreateCompletionRequest(
            model: Model.davinci002.id,
            prompt: .string(isTheWaterWetYesOrNo),
            isStream: true
        )
        let stream = try client.streamingCompletion(request: request)
        var text = ""
        for await chunk in stream {
            text.append(chunk.map { $0.firstChoice }.joined())
        }
        XCTAssertFalse(text.isEmpty)
    }
    
    /// See [Create streaming completion](https://platform.openai.com/docs/api-reference/completions/create)
    func testStreamingCompletion_terminatesWithFinishReason() async throws {
        var isEventHandlerCalled = false
        let chunkHandler: ([CompletionChunk]) throws -> Void = { chunks in
            isEventHandlerCalled = true
            for chunk in chunks {
                let chunkString = try JSON.toString(chunk) ?? ""
                self.log.debug("new chunk: \(chunkString)")
            }
        }

        let streamClient = try client.streamingCompletion(
            request: .init(model: Model.davinci003.id, prompt: .string(isTheWaterWetYesOrNo)),
            streamListener: chunkHandler
        )
        streamClient.start()

        let predicate = NSPredicate(block: { object, _ in
            guard let streamClient = object as? StreamingClient else { return false }
            return streamClient.state == .shutdown
        })
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: streamClient)
        let res = await XCTWaiter.fulfillment(of: [expectation], timeout: 10.0)
        if res != XCTWaiter.Result.completed {
            XCTFail("Expected the event source to finish with shutdown")
         }
        XCTAssertTrue(isEventHandlerCalled, "Expected eventHandler to receive calls.")
    }
}
