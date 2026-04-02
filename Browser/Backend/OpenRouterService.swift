import Foundation

struct OpenRouterRequest: Codable {
    let model: String
    let messages: [Message]
    let stream: Bool?

    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct OpenRouterResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}

class OpenRouterService {
    static let shared = OpenRouterService()
    private let baseURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    func fetchCompletion(apiKey: String, model: String, prompt: String, context: String) async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages = [
            OpenRouterRequest.Message(role: "system", content: "You are a helpful browser assistant. Use the following page content as context: \(context)"),
            OpenRouterRequest.Message(role: "user", content: prompt)
        ]

        let requestBody = OpenRouterRequest(model: model, messages: messages, stream: false)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "OpenRouterService", code: 0, userInfo: [NSLocalizedDescriptionKey: "API Request failed"])
        }

        let decodedResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        return decodedResponse.choices.first?.message.content ?? "No response from AI"
    }
}
