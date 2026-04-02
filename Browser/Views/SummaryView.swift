import SwiftUI

struct SummaryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var aiConfig: AIConfiguration
    @ObservedObject var viewModel: BrowserViewModel
    @State private var summary: String = "Summarizing..."
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isLoading {
                        ProgressView("Analyzing page content...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    } else {
                        Text(summary)
                            .font(.body)
                            .padding()
                    }
                }
            }
            .navigationTitle("Page Summary")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            })
        }
        .onAppear {
            summarizePage()
        }
    }

    private func summarizePage() {
        Task {
            let content = await viewModel.extractPageContent()
            guard !content.isEmpty else {
                errorMessage = "Could not extract page content."
                isLoading = false
                return
            }

            do {
                let result = try await OpenRouterService.shared.fetchCompletion(
                    apiKey: aiConfig.apiKey,
                    model: aiConfig.currentModel,
                    prompt: "Please provide a concise summary of this page content.",
                    context: content
                )
                summary = result
                isLoading = false
            } catch {
                errorMessage = "Failed to summarize: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
