import Foundation
import Combine

@available(iOS 16.0, *)
@MainActor
class AutoNotesManager: ObservableObject {
    static let shared = AutoNotesManager()

    @Published var isGenerating = false
    @Published var lastGeneratedNote: String?

    private let aiConfig = AIConfiguration()
    private let learning = AutoNotesLearning.shared

    func generateNote(for url: URL?, content: String) async {
        guard let host = url?.host else { return }

        self.isGenerating = true
        self.lastGeneratedNote = nil

        let learnedContext = learning.getLearnedContext(for: host)
        let prompt = """
        Analyze the following page content and generate a concise, clean Markdown note.
        Consider the following learned user interests for this domain: \(learnedContext).

        Page Content:
        \(content.prefix(2000))

        Format the output as a Markdown note with a title.
        """

        do {
            let result = try await OpenRouterService.shared.fetchCompletion(
                apiKey: aiConfig.apiKey,
                model: aiConfig.selectedModel,
                prompt: prompt,
                context: "Auto-generating a note based on page content and learned patterns."
            )

            self.lastGeneratedNote = result
            self.isGenerating = false
        } catch {
            print("AutoNotesManager: Error generating note: \(error)")
            self.isGenerating = false
        }
    }
}
