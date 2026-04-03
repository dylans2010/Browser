import SwiftUI

@available(iOS 16.0, *)
struct SummaryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var aiConfig: AIConfiguration
    @ObservedObject var viewModel: BrowserViewModel
    @State private var summary: String = "Summarizing..."
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var isCopied: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1), .pink.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if isLoading {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .progressViewStyle(ModernLoadingStyle())
                                Text("Analyzing page content...")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                        } else if let error = errorMessage {
                            GroupBox {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(error)
                                        .foregroundColor(.red)
                                }
                                .padding()
                            }
                            .padding()
                        } else {
                            GroupBox {
                                Text(cleanSummary)
                                    .font(.body)
                                    .padding(5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .groupBoxStyle(ModernGroupBoxStyle())
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Page Summary")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        UIPasteboard.general.string = cleanSummary
                        isCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isCopied = false
                        }
                    }) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .foregroundColor(isCopied ? .green : .blue)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            summarizePage()
        }
    }

    private var cleanSummary: String {
        var text = summary
        // Very basic markdown stripping:
        text = text.replacingOccurrences(of: "\\*\\*", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\*", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "#", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "`", with: "", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
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
                    prompt: "Please provide a concise summary of this page content. Use markdown for better formatting, including bold text, bullet points, and headers where appropriate.",
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

struct ModernLoadingStyle: ProgressViewStyle {
    @State private var isAnimating = false

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                .frame(width: 50, height: 50)

            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(gradient: Gradient(colors: [.blue, .purple, .pink]), startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .onAppear {
                    withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
        }
    }
}

struct ModernGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
