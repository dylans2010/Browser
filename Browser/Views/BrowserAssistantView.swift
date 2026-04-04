import SwiftUI

@available(iOS 16.0, *)
struct BrowserAssistantView: View {
    @EnvironmentObject var browserViewModel: BrowserViewModel
    @Environment(\.dismiss) var dismiss

    @StateObject var selectionManager = SelectionManager.shared

    @State private var userInput: String = ""
    @State private var aiResult: String = ""
    @State private var isLoading: Bool = false
    @State private var showResult: Bool = false

    var body: some View {
        ZStack {
            // Non-obstructive background (just handles dismissal if tapping outside banners)
            Color.black.opacity(0.001)
                .onTapGesture {
                    if selectionManager.selectedText.isEmpty {
                        selectionManager.disableSelectionMode()
                        dismiss()
                    }
                }

            VStack {
                // Top Selection Mode Banner
                if selectionManager.selectedText.isEmpty {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                        Text("Select an element to analyze")
                            .font(.subheadline.bold())

                        Spacer()

                        Button(action: {
                            selectionManager.disableSelectionMode()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(Capsule().fill(.ultraThinMaterial))
                    .padding(.top, 60)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                if !selectionManager.selectedText.isEmpty {
                    // Floating Action Card at the bottom
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Selected Content")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                Text(selectionManager.selectedText)
                                    .font(.system(size: 14))
                                    .lineLimit(2)
                            }
                            Spacer()
                            Button(action: {
                                selectionManager.selectedText = ""
                                if let webView = browserViewModel.activeTab?.webView {
                                    selectionManager.enableSelectionMode(in: webView)
                                }
                            }) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)

                        Divider()

                        HStack(spacing: 10) {
                            actionButton(title: "Summarize", icon: "text.alignleft") { runAI(instruction: "Summarize the following content:") }
                            actionButton(title: "Explain", icon: "info.circle") { runAI(instruction: "Explain the following content clearly:") }
                            actionButton(title: "Rewrite", icon: "pencil") { runAI(instruction: "Rewrite the following content to be more engaging:") }
                        }
                        .padding(.horizontal)

                        HStack {
                            TextField("Ask AI anything...", text: $userInput)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))

                            if !userInput.isEmpty {
                                Button(action: { runAI(instruction: userInput) }) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }

                            Button(action: {
                                selectionManager.disableSelectionMode()
                                dismiss()
                            }) {
                                Text("Done")
                                    .bold()
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    .padding(.vertical)
                    .background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            if isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("AI is thinking...")
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                }
            }
        }
        .sheet(isPresented: $showResult) {
            AIResultView(title: "Assistant Result", content: aiResult, isLoading: false)
        }
        .onAppear {
            if let webView = browserViewModel.activeTab?.webView {
                selectionManager.enableSelectionMode(in: webView)
            }
        }
    }

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.headline)
                Text(title)
                    .font(.caption2.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private func runAI(instruction: String) {
        isLoading = true
        let selectedText = selectionManager.selectedText
        let url = browserViewModel.activeTab?.url?.absoluteString ?? "unknown"

        Task {
            do {
                let config = AIConfiguration()
                let result = try await OpenRouterService.shared.fetchCompletion(
                    apiKey: config.apiKey,
                    model: config.selectedModel,
                    prompt: "\(instruction)\n\nContent:\n\(selectedText)",
                    context: "Selected content from \(url)"
                )

                DispatchQueue.main.async {
                    self.aiResult = result
                    self.isLoading = false
                    self.showResult = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.aiResult = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                    self.showResult = true
                }
            }
        }
    }
}
