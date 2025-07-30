import OpenAIAPI
import OpenAIClient
import XCTest

final class UsageTests: BaseTests {
    func testUsage() async throws {
        // COMPLETION
        let prompt = "hello there chatgpt!"
        let response = try await client.completions(request: .init(model: Model.davinci003.id, prompt: .string(prompt)))
        print("response: \(response.choices.first?.text as Any)")

        // STREAMING COMPLETION
        let streamClient = try client.streamingChatCompletion(
            streamListener: { print("chunks \($0.map { $0.firstChoice })") },
            modelId: Model.gpt35turbo.id,
            conversation: [ChatCompletionRequestMessage(role: .user, content: prompt)]
        )
        streamClient.start()

        // wait for streamClient shutdown
        let predicate = NSPredicate(block: { object, _ in
            guard let streamClient = object as? StreamingClient else { return false }
            return streamClient.state == .shutdown
        })
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: streamClient)
        let res = await XCTWaiter.fulfillment(of: [expectation], timeout: 20.0)
        if res != XCTWaiter.Result.completed {
            XCTFail("Expected the event source to finish with shutdown")
         }
    }
}
