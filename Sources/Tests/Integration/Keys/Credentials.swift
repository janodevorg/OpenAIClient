import Foundation
@testable import OpenAIClient

struct Credentials: Decodable {
    let apiKey: String
    let organizationId: String

    var credentials: [String: String] {
        [
            "apiKey": apiKey,
            "organizationId": organizationId
        ]
    }

    /// Returns real credentials from file `credentials.json`.
    static func instance() -> Credentials? {
        do {
            guard let url = Bundle.module.url(forResource: "credentials", withExtension: "json") else {
                log.error("Missing file in the bundle. Please create file \"Tests/Integration/resources/credentials.json\"")
                return nil
            }
            let jsonData = try Data(contentsOf: url)
            let credentials = try JSONDecoder().decode(Credentials.self, from: jsonData)
            if credentials.apiKey.isEmpty || credentials.organizationId.isEmpty {
                log.warn("Credentials are empty. Check the README.")
                return nil
            }
            return credentials
        } catch {
            log.error("\(error)")
        }
        return nil
    }

    private static var log: DumpLogger {
        DumpLogger(label: "Credentials")
    }
}
