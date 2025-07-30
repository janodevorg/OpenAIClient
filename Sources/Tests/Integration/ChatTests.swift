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
    func testStreamingChat_asyncStream() async throws {
        let conversation = [ChatCompletionRequestMessage(role: .user, content: isTheWaterWetYesOrNo)]
        let stream = try client.streamingChatCompletion(modelId: Model.gpt35turbo.id, conversation: conversation)
        var text = ""
        for await chunk in stream {
            text.append(chunk.map { $0.firstChoice }.joined())
        }
        XCTAssertFalse(text.isEmpty)
    }

    /// See [Create chat completion](https://platform.openai.com/docs/api-reference/chat/create)
    func testStreamingChat_terminatesWithFinishReason() async throws {
        let finishReasonExpectation = expectation(description: "Finish reason provided")
        let testChunkForFinishReason: @Sendable ([ChatChunk]) throws -> Void = { chunks in
            for chunk in chunks {
                let chunkString = try JSON.toString(chunk) ?? ""
                print("Chat chunk: \(chunkString)")
                if let finishReason = chunk.choices.last?.finishReason {
                    print("finishReason: \(finishReason)")
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

        let res = await XCTWaiter.fulfillment(of: [finishReasonExpectation], timeout: 30.0)
        if res != XCTWaiter.Result.completed {
            XCTFail("Expected the event source to finish with finish reason")
         }
    }

    /// See [Create chat completion](https://platform.openai.com/docs/api-reference/chat/create)
    func testStreamingChat_terminatesWithEventSourceShutdown() async throws {
        let expectation = expectation(description: "Stream handler called")
        let streamClient = try client.streamingChatCompletion(
            streamListener: { @Sendable chunks in
                expectation.fulfill()
                for chunk in chunks {
                    let chunkString = try JSON.toString(chunk) ?? ""
                    print("Chunk: \(chunkString)")
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
        let shutdownExpectation = XCTNSPredicateExpectation(predicate: predicate, object: streamClient)
        let res = await XCTWaiter.fulfillment(of: [expectation, shutdownExpectation], timeout: 10.0)
        if res != XCTWaiter.Result.completed {
            XCTFail("Expected the event source to finish with shutdown and handler to be called")
         }
    }
}
