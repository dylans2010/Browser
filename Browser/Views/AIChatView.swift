import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let role: String
    let content: String
}

@available(iOS 16.0, *)
struct AIChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var aiConfig: AIConfiguration
    @ObservedObject var viewModel: BrowserViewModel
    @State private var messages: [Message] = []
    @State private var userInput: String = ""
    @State private var isSending: Bool = false
    @State private var pageContent: String = ""

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            HStack {
                                if message.role == "user" { Spacer() }

                                Text(message.content)
                                    .padding(10)
                                    .background(message.role == "user" ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(message.role == "user" ? .white : .primary)
                                    .cornerRadius(12)

                                if message.role != "user" { Spacer() }
                            }
                        }
                    }
                    .padding()
                }

                HStack {
                    TextField("Ask something about this page...", text: $userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isSending)

                    if isSending {
                        ProgressView()
                            .padding(.horizontal, 8)
                    } else {
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                        }
                        .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding()
            }
            .navigationTitle("Ask the Page")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            })
            .onAppear {
                Task {
                    pageContent = await viewModel.extractPageContent()
                    if messages.isEmpty {
                        messages.append(Message(role: "assistant", content: "Hello! I've analyzed this page. What would you like to know?"))
                    }
                }
            }
        }
    }

    private func sendMessage() {
        let userText = userInput.trimmingCharacters(in: .whitespaces)
        guard !userText.isEmpty else { return }

        messages.append(Message(role: "user", content: userText))
        userInput = ""
        isSending = true

        Task {
            do {
                let response = try await OpenRouterService.shared.fetchCompletion(
                    apiKey: aiConfig.apiKey,
                    model: aiConfig.currentModel,
                    prompt: userText,
                    context: pageContent
                )
                messages.append(Message(role: "assistant", content: response))
            } catch {
                messages.append(Message(role: "assistant", content: "Error: \(error.localizedDescription)"))
            }
            isSending = false
        }
    }
}
