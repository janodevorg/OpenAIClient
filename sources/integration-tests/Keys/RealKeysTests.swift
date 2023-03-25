import XCTest

final class RealKeysTests: XCTestCase {
    private let realKeys = RealKeys.instance()

    func testCredentialsProvided() throws {
        guard let realKeys = realKeys else {
            throw XCTSkip("Credentials file not available.")
        }
        XCTAssertNotNil(realKeys.apiKey)
        XCTAssertNotNil(realKeys.organizationId)
    }
}
