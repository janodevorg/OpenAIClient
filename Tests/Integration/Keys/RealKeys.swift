import Foundation
@testable import OpenAIClient

struct RealKeys: Decodable {
    let apiKey: String
    let organizationId: String
    let hostName: String

    var credentials: [String: String] {
        [
            "apiKey": apiKey,
            "organizationId": organizationId
        ]
    }

    /// Returns real keys from file `realKeys.json`.
    static func instance() -> RealKeys? {
        do {
            guard let url = Bundle.module.url(forResource: "realKeys", withExtension: "json") else {
                log.error("Missing file in the bundle. Please create file \"resources/realKeys.json\"")
                return nil
            }
            let jsonData = try Data(contentsOf: url)
            let realKeys = try JSONDecoder().decode(RealKeys.self, from: jsonData)
            if realKeys.apiKey.isEmpty || realKeys.organizationId.isEmpty {
                log.warn("Credentials are empty. Check the README.")
                return nil
            }
            return realKeys
        } catch {
            log.error("\(error)")
        }
        return nil
    }

    private static var log: DumpLogger {
        DumpLogger(label: "RealKeys")
    }
}
