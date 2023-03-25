import Atlantis
import CustomDump
import DumpLogger
import Logger
import OpenAIAPI
@testable import OpenAIClient
import XCTest

/**
 Base class for integration tests.

 ⚠️ BEWARE - THESE ARE INTEGRATION TESTS ⚠️

 They will spend a small number of tokens and remove files/fine-tunes/models in your Organization.
 I wrote these tests to run them manually as an aid for debugging.
 If there is nothing of value in your account you are safe to run them.
 */
class BaseTests: XCTestCase {
    /// Models called during testing.
    enum Model: String {
        case baseAda = "ada"
        case codeDavinciEdit001 = "code-davinci-edit-001"
        case davinci003 = "text-davinci-003"
        case davinciEdit001 = "text-davinci-edit-001"
        case embeddingAda002 = "text-embedding-ada-002"
        case gpt35turbo = "gpt-3.5-turbo"
        case moderationLatest = "text-moderation-stable"
        case whisper1 = "whisper-1"

        var id: String {
            rawValue
        }
    }

    var client: OpenAIClient! // swiftlint:disable:this implicitly_unwrapped_optional
    var log: Logger! // swiftlint:disable:this implicitly_unwrapped_optional

    // MARK: - Resources

    let isTheWaterWetYesOrNo = "Please answer using a single word: yes or no. Is the water wet?"
    let image = BaseTests.image(resource: "image", extension: "png")
    let mask = BaseTests.image(resource: "mask", extension: "png")

    static func image(resource: String, extension ext: String) -> CPImage? {
        guard let url = Bundle.module.url(forResource: resource, withExtension: ext) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return CPImage(data: data)
    }

    // MARK: - SetUp

    override func setUp() async throws {
        guard let keys = RealKeys.instance() else {
            throw XCTSkip("Skipping test because credentials are missing.")
        }

        if !keys.hostName.isEmpty {
            Atlantis.start(hostName: keys.hostName)
        }

        log = DumpLogger(label: "tests", threshold: .debug)
        client = OpenAIClient(log: .debug)
        client.configure(apiKey: keys.apiKey, companyKey: keys.organizationId)
    }

    // MARK: - Private

    func firstFileSkipIfEmpty(file: StaticString = #filePath, line: UInt = #line) async throws -> OpenAIFile {
        if let file = try await client.files().data.first {
            return file
        }
        throw XCTSkip("No files found.", file: file, line: line)
    }

    func dumpJSONCatchingErrors(file: StaticString = #filePath, function: String = #function, line: UInt = #line, _ closure: () async throws -> Encodable) async {
        do {
            let jsonString = try JSON.toString(try await closure())
            let unwrappedJsonString = try XCTUnwrap(jsonString, file: file, line: line)
            log.debug(unwrappedJsonString)
        } catch {
            log.error(error, file: String(describing: file), function: function, line: line)
            var message = ""
            customDump(error, to: &message)
            XCTFail(message, file: file, line: line)
        }
    }
}
