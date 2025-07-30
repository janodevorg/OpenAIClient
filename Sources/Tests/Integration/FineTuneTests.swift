import OpenAIAPI
@testable import OpenAIClient
import XCTest

final class FineTuneTests: BaseTests {
    // {"prompt": "<prompt text>", "completion": "<ideal generated text>"}
    private let fileContent = """
    {"prompt": "Why do people like soccer?", "completion": "It dispenses joy and misery at random. mimics life."}
    """

    /// This only works with base models `ada` (cheapest), `babbage`, `curie`, or `davinci` (more capable).
    /// See [Create fine-tune](https://platform.openai.com/docs/api-reference/fine-tunes/create)
    func testCreateFineTune() async throws {
        await dumpJSONCatchingErrors {
            // upload a file and create a fine-tune from it
            let finetune = try await client.uploadFile(
                fileContent: fileContent,
                filename: "testCreateFineTune.jsonl",
                purpose: "fine-tune"
            )
            let request = CreateFineTuneRequest(trainingFile: finetune.id, model: Model.baseAda.id)
            return try await self.client.createFineTune(fineTuneRequest: request)
        }
    }

    /// See [List fine-tunes](https://platform.openai.com/docs/api-reference/fine-tunes/list)
    func testListFineTunes() async throws {
        await dumpJSONCatchingErrors {
            try await self.client.listFineTunes()
        }
    }

    /// See [Retrieve fine-tune](https://platform.openai.com/docs/api-reference/fine-tunes/retrieve)
    func testRetrieveFineTune() async throws {
        guard let firstFineTune = try await client.listFineTunes().data.first else {
            throw XCTSkip("Can’t retrieve a fine-tune with none available.")
        }
        await dumpJSONCatchingErrors {
            try await self.client.retrieveFineTune(id: firstFineTune.id)
        }
    }

    /// See [Cancel fine-tune](https://platform.openai.com/docs/api-reference/fine-tunes/cancel)
    func testCancelFineTune() async throws {
        let fineTune = try await client.listFineTunes().data.first(where: { !["succeeded", "cancelled"].contains($0.status) })
        guard let firstFineTune = fineTune else {
            throw XCTSkip("Can’t cancel a fine tune with none ongoing.")
        }
        await dumpJSONCatchingErrors {
            try await self.client.cancelFineTune(id: firstFineTune.id)
        }
    }

    /// See [List fine-tune events](https://platform.openai.com/docs/api-reference/fine-tunes/events)
    func testListFineTuneEvents() async throws {
        // Find a model created by the user
        let model = try await client.models().data.first(where: {
            $0.ownedBy.hasPrefix("user-")
        })
        guard let modelId = model?.id else {
            throw XCTSkip("Can’t stream events because I found no models created by the user.")
        }

        // Find the fine-tune for that model
        let firstFineTune = try await client.listFineTunes().data.first(where: {
            $0.fineTunedModel == modelId
        })
        guard let fineTuneId = firstFineTune?.id else {
            throw XCTSkip("Couldn’t find the fine-tune for model \(modelId)")
        }

        await dumpJSONCatchingErrors {
            try await self.client.listFineTuneEvents(id: fineTuneId)
        }
    }

    /// See [List fine-tune events](https://platform.openai.com/docs/api-reference/fine-tunes/events)
    func testStreamListFineTuneEvents() async throws {
        // Find a model created by the user
        let model = try await client.models().data.first(where: {
            $0.ownedBy.hasPrefix("user-")
        })
        guard let modelId = model?.id else {
            throw XCTSkip("Can’t stream events because I found no models created by the user.")
        }

        // Find the fine-tune for that model
        let firstFineTune = try await client.listFineTunes().data.first(where: {
            $0.fineTunedModel == modelId
        })
        guard let fineTuneId = firstFineTune?.id else {
            throw XCTSkip("Couldn’t find the fine-tune for model \(modelId)")
        }

        var isEventHandlerCalled = false
        let eventHandler: ([FineTuneEvent]) throws -> Void = { chunks in
            isEventHandlerCalled = true
            for chunk in chunks {
                let chunkString = try JSON.toString(chunk) ?? ""
                self.log.debug("new chunk: \(chunkString)")
            }
        }

        let streamClient = try await client.streamingListFineTuneEvents(id: fineTuneId, streamListener: eventHandler)
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
    
    /// See [List fine-tune events](https://platform.openai.com/docs/api-reference/fine-tunes/events)
    func testStreamListFineTuneEvents_asyncStream() async throws {
        // Find a model created by the user
        let model = try await client.models().data.first(where: {
            $0.ownedBy.hasPrefix("user-")
        })
        guard let modelId = model?.id else {
            throw XCTSkip("Can’t stream events because I found no models created by the user.")
        }

        // Find the fine-tune for that model
        let firstFineTune = try await client.listFineTunes().data.first(where: {
            $0.fineTunedModel == modelId
        })
        guard let fineTuneId = firstFineTune?.id else {
            throw XCTSkip("Couldn’t find the fine-tune for model \(modelId)")
        }
            
        let stream = try client.streamingListFineTuneEvents(id: fineTuneId)
        var events = [FineTuneEvent]()
        for await fineTuneEvents in stream {
            for event in fineTuneEvents {
                events.append(event)
            }
        }
        XCTAssertFalse(events.isEmpty)
    }

    /// See [Delete fine-tune model](https://platform.openai.com/docs/api-reference/fine-tunes/delete-model)
    func testDeleteFineTuneModel() async throws {
        let model = try await client.models().data.first(where: {
            $0.ownedBy.hasPrefix("user-")
        })
        guard let id = model?.id else {
            throw XCTSkip("Can’t delete a user model because I found none.")
        }
        await dumpJSONCatchingErrors {
            try await self.client.deleteFineTuneModel(id: id)
        }
    }
}
