import OpenAIAPI
@testable import OpenAIClient
import XCTest

final class ChatTests: BaseTests {
    /// See [Create chat completion](https://platform.openai.com/docs/api-reference/chat/create)
    func testChatCompletion() async throws {
        await dumpJSONCatchingErrors {
            try await client.chatCompletion(
                id: Model.gpt35turbo.id,
                conversation: [ChatCompletionRequestMessage(role: .user, content: "how high can you jump?")]
            )
        }
    }

    /// See [Create chat completion](https://platform.openai.com/docs/api-reference/chat/create)
    func testStreamingChat_terminatesWithFinishReason() async throws {
        let finishReasonExpectation = expectation(description: "Finish reason provided")
        var isEventHandlerCalled = false
        let testChunkForFinishReason: ([ChatChunk]) throws -> Void = { chunks in
            isEventHandlerCalled = true
            for chunk in chunks {
                let chunkString = try JSON.toString(chunk) ?? ""
                self.log.debug("new chunk: \(chunkString)")
                if let finishReason = chunk.choices.last?.finishReason {
                    self.log.debug("finishReason: \(finishReason)")
                    finishReasonExpectation.fulfill()
                    return
                }
            }
        }

        let streamClient = try client.streamingChatCompletion(
            streamListener: testChunkForFinishReason,
            modelId: Model.gpt35turbo.id,
            conversation: [ChatCompletionRequestMessage(role: .user, content: isTheWaterWetYesOrNo)]
        )
        streamClient.start()

        wait(for: [finishReasonExpectation], timeout: 30)
        XCTAssertTrue(isEventHandlerCalled, "Expected eventHandler to receive calls.")
    }

    /// See [Create chat completion](https://platform.openai.com/docs/api-reference/chat/create)
    func testStreamingChat_terminatesWithEventSourceShutdown() async throws {
        var isEventHandlerCalled = false
        let streamClient = try client.streamingChatCompletion(
            streamListener: { chunks in
                isEventHandlerCalled = true
                for chunk in chunks {
                    let chunkString = try JSON.toString(chunk) ?? ""
                    self.log.debug(chunkString)
                }
            },
            modelId: Model.gpt35turbo.id,
            conversation: [ChatCompletionRequestMessage(role: .user, content: isTheWaterWetYesOrNo)]
        )
        streamClient.start()

        let predicate = NSPredicate(block: { object, _ in
            guard let streamClient = object as? StreamingClient else { return false }
            return streamClient.state == .shutdown
        })
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: streamClient)
        let res = XCTWaiter.wait(for: [expectation], timeout: 10.0)
        if res != XCTWaiter.Result.completed {
            XCTFail("Expected the event source to finish with shutdown")
         }
        XCTAssertTrue(isEventHandlerCalled, "Expected eventHandler to receive calls.")
    }
}
