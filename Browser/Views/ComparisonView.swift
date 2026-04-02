import SwiftUI

struct ComparisonView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var aiConfig: AIConfiguration
    @ObservedObject var viewModel: BrowserViewModel
    @State private var selectedTabIds: Set<UUID> = []
    @State private var comparisonResult: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                if comparisonResult.isEmpty && !isLoading {
                    List(viewModel.tabs, selection: $selectedTabIds) { tab in
                        HStack {
                            Text(tab.title)
                                .lineLimit(1)
                            Spacer()
                            if selectedTabIds.contains(tab.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedTabIds.contains(tab.id) {
                                selectedTabIds.remove(tab.id)
                            } else {
                                selectedTabIds.insert(tab.id)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())

                    Button(action: compareSelectedTabs) {
                        Text("Compare Selected Tabs")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedTabIds.count < 2 ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(selectedTabIds.count < 2)
                    .padding()
                } else if isLoading {
                    ProgressView("Analyzing and comparing...")
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                    Button("Try Again") {
                        comparisonResult = ""
                        errorMessage = nil
                    }
                } else {
                    ScrollView {
                        Text(comparisonResult)
                            .padding()
                    }
                }
            }
            .navigationTitle("Compare Tabs")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar{
                Group {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                    if !comparisonResult.isEmpty {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Reset") {
                                comparisonResult = ""
                                selectedTabIds = []
                            }
                        }
                    }
                }
            })
        }
    }

    private func compareSelectedTabs() {
        isLoading = true
        errorMessage = nil

        Task {
            var combinedContext = ""
            for tabId in selectedTabIds {
                if let tab = viewModel.tabs.first(where: { $0.id == tabId }) {
                    let content = await extractContent(from: tab)
                    combinedContext += "Content from \(tab.title):\n\(content)\n\n"
                }
            }

            do {
                let result = try await OpenRouterService.shared.fetchCompletion(
                    apiKey: aiConfig.apiKey,
                    model: aiConfig.currentModel,
                    prompt: "Compare the information across these pages and provide a structured comparison highlighting key differences and similarities.",
                    context: combinedContext
                )
                comparisonResult = result
                isLoading = false
            } catch {
                errorMessage = "Comparison failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func extractContent(from tab: TabItem) async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                tab.webView.evaluateJavaScript("document.body.innerText") { (result, error) in
                    continuation.resume(returning: result as? String ?? "")
                }
            }
        }
    }
}
