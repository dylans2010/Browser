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
            // Fullscreen Glass Overlay
            Color.clear
                .background(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: {
                        selectionManager.disableSelectionMode()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                }
                .padding()

                Spacer()

                if !selectionManager.selectedText.isEmpty {
                    // Assistant Action Sheet
                    VStack(spacing: 20) {
                        Text("Selected Content")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ScrollView {
                            Text(selectionManager.selectedText)
                                .font(.body)
                                .lineLimit(10)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
                        }
                        .frame(maxHeight: 200)

                        TextField("What do you want AI to do?", text: $userInput)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            actionButton(title: "Summarize", action: { runAI(instruction: "Summarize the following content:") })
                            actionButton(title: "Explain", action: { runAI(instruction: "Explain the following content clearly:") })
                            actionButton(title: "Rewrite", action: { runAI(instruction: "Rewrite the following content to be more engaging:") })
                        }

                        if !userInput.isEmpty {
                            Button("Execute Custom Action") {
                                runAI(instruction: userInput)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial))
                    .padding()
                    .transition(.move(edge: .bottom))
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)

                        Text("Browser Assistant")
                            .font(.largeTitle.bold())

                        Text("Tap on any element or text on the page to analyze it with AI.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                }

                Spacer()
            }

            if isLoading {
                ProgressView("AI is thinking...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
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

    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .controlSize(.small)
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
