import OpenAIClient

//let apiKey = "" // get it from https://platform.openai.com/account/api-keys
//let orgId = ""  // get it from https://platform.openai.com/account/org-settings

struct MissingCredentials: Error, CustomStringConvertible {
    var description: String {
        "👉 Please edit the file Sources/SwiftAI/makeClient.swift with your OpenAI credentials."
    }
}

func makeClient() throws -> OpenAIClient {
    guard !apiKey.isEmpty && !orgId.isEmpty else {
        throw MissingCredentials()
    }
    let client = OpenAIClient(log: .error)
    client.configure(apiKey: apiKey, companyKey: orgId)
    return client
}
