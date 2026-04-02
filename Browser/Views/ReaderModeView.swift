import SwiftUI

struct ReaderModeView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BrowserViewModel
    @State private var content: String = ""
    @State private var fontSize: CGFloat = 18
    @State private var isLoading: Bool = true

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Extracting readable content...")
                } else {
                    ScrollView {
                        Text(content)
                            .font(.system(size: fontSize))
                            .padding()
                    }
                }
            }
            .navigationTitle("Reader Mode")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar(content: {
                Group {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        HStack {
                            Button(action: { fontSize = max(12, fontSize - 2) }) {
                                Image(systemName: "textformat.size.smaller")
                            }
                            Button(action: { fontSize = min(36, fontSize + 2) }) {
                                Image(systemName: "textformat.size.larger")
                            }
                        }
                    }
                }
            })
            .onAppear {
                Task {
                    content = await viewModel.extractPageContent()
                    isLoading = false
                }
            }
        }
    }
}
