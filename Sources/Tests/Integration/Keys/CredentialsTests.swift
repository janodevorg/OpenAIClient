import XCTest

final class CredentialsTests: XCTestCase {
    private let credentials = Credentials.instance()

    func testCredentialsProvided() throws {
        guard let credentials = credentials else {
            throw XCTSkip("Credentials file not available.")
        }
        XCTAssertNotNil(credentials.apiKey)
        XCTAssertNotNil(credentials.organizationId)
    }
}
