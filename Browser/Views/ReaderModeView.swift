import SwiftUI

struct ReaderModeView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BrowserViewModel
    @State private var content: String = ""
    @State private var fontSize: CGFloat = 18
    @State private var theme: String = "Light"
    @State private var fontName: String = "System"
    @State private var isLoading: Bool = true

    var body: some View {
        NavigationView {
            ZStack {
                themeColor.edgesIgnoringSafeArea(.all)

                VStack {
                    if isLoading {
                        ProgressView("Extracting readable content...")
                    } else {
                        ScrollView {
                            Text(content)
                                .font(selectedFont)
                                .foregroundColor(textColor)
                                .padding()
                        }
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
                        Menu {
                            Picker("Theme", selection: $theme) {
                                Text("Light").tag("Light")
                                Text("Dark").tag("Dark")
                                Text("Sepia").tag("Sepia")
                            }
                            Picker("Font", selection: $fontName) {
                                Text("System").tag("System")
                                Text("Serif").tag("Serif")
                                Text("Monospace").tag("Monospace")
                            }
                            Divider()
                            HStack {
                                Button(action: { fontSize = max(12, fontSize - 2) }) {
                                    Label("Smaller", systemImage: "textformat.size.smaller")
                                }
                                Button(action: { fontSize = min(36, fontSize + 2) }) {
                                    Label("Larger", systemImage: "textformat.size.larger")
                                }
                            }
                        } label: {
                            Image(systemName: "textformat")
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

    private var themeColor: Color {
        switch theme {
        case "Dark": return Color.black
        case "Sepia": return Color(red: 244/255, green: 235/255, blue: 215/255)
        default: return Color.white
        }
    }

    private var textColor: Color {
        switch theme {
        case "Dark": return Color.white
        case "Sepia": return Color(red: 95/255, green: 75/255, blue: 50/255)
        default: return Color.black
        }
    }

    private var selectedFont: Font {
        switch fontName {
        case "Serif": return .custom("Georgia", size: fontSize)
        case "Monospace": return .custom("Courier", size: fontSize)
        default: return .system(size: fontSize)
        }
    }
}
