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
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) { _ in
                            if let lastId = messages.last?.id {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Bottom Input Area
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            TextField("Ask something about this page...", text: $userInput, axis: .vertical)
                                .lineLimit(1...5)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(20)
                                .disabled(isSending)

                            if isSending {
                                ProgressView()
                                    .frame(width: 44, height: 44)
                            } else {
                                Button(action: sendMessage) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 32))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundColor(.blue)
                                }
                                .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    }
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Ask the Page")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                        Text("AI Assistant")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
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

@available(iOS 16.0, *)
struct ChatBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.role == "user" { Spacer() }

            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.role == "user" ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
                    .foregroundColor(message.role == "user" ? .white : .primary)
                    .clipShape(BubbleShape(isUser: message.role == "user"))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }

            if message.role != "user" { Spacer() }
        }
    }
}

struct BubbleShape: Shape {
    var isUser: Bool

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: isUser ? [.topLeft, .bottomLeft, .bottomRight] : [.topRight, .bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: 18, height: 18)
        )
        return Path(path.cgPath)
    }
}
