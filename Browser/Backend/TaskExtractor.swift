import Foundation

struct TaskItem: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let status: TaskStatus

    enum TaskStatus: String, Codable {
        case pending, completed
    }
}

class TaskExtractor {
    static let shared = TaskExtractor()

    func extractTasks(from content: String, apiKey: String, model: String) async throws -> [TaskItem] {
        let prompt = "Extract actionable tasks from the following text and return them in a JSON array format. Each task should have a 'title' and a 'description'. Return only the JSON array, no other text."

        let response = try await OpenRouterService.shared.fetchCompletion(
            apiKey: apiKey,
            model: model,
            prompt: prompt,
            context: content
        )

        guard let data = response.data(using: .utf8) else { return [] }

        let tasks = try JSONDecoder().decode([TaskItem].self, from: data)
        return tasks
    }
}
