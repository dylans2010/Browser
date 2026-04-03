import SwiftUI

@available(iOS 16.0, *)
struct ReaderModeView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BrowserViewModel
    @State private var content: String = ""
    @State private var fontSize: CGFloat = 18
    @State private var lineHeight: CGFloat = 1.5
    @State private var letterSpacing: CGFloat = 0.0
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
                                .lineSpacing(fontSize * (lineHeight - 1))
                                .tracking(letterSpacing)
                                .foregroundColor(textColor)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .navigationTitle("Reader Mode")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                Group {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Section("Theme") {
                                Picker("Theme", selection: $theme) {
                                    Label("Light", systemImage: "sun.max").tag("Light")
                                    Label("Dark", systemImage: "moon").tag("Dark")
                                    Label("Sepia", systemImage: "leaf").tag("Sepia")
                                    Label("Paper", systemImage: "doc.text").tag("Paper")
                                }
                            }

                            Section("Font") {
                                Picker("Font", selection: $fontName) {
                                    Text("System").tag("System")
                                    Text("Serif").tag("Serif")
                                    Text("Monospace").tag("Monospace")
                                    Text("Avenir").tag("Avenir")
                                    Text("Charter").tag("Charter")
                                }
                            }

                            Section("Size") {
                                ControlGroup {
                                    Button(action: { fontSize = max(12, fontSize - 2) }) {
                                        Label("Smaller", systemImage: "textformat.size.smaller")
                                    }
                                    Button(action: { fontSize = min(36, fontSize + 2) }) {
                                        Label("Larger", systemImage: "textformat.size.larger")
                                    }
                                }
                            }

                            Section("Spacing") {
                                Menu("Line Height") {
                                    Picker("Line Height", selection: $lineHeight) {
                                        Text("Tight").tag(1.2)
                                        Text("Normal").tag(1.5)
                                        Text("Wide").tag(2.0)
                                    }
                                }
                                Menu("Letter Spacing") {
                                    Picker("Letter Spacing", selection: $letterSpacing) {
                                        Text("Normal").tag(0.0)
                                        Text("Loose").tag(1.0)
                                        Text("Very Loose").tag(2.0)
                                    }
                                }
                            }

                        } label: {
                            Image(systemName: "textformat")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(8)
                                .background(Circle().fill(Color.primary.opacity(0.1)))
                        }
                    }
                }
            }
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
        case "Paper": return Color(red: 250/255, green: 250/255, blue: 245/255)
        default: return Color.white
        }
    }

    private var textColor: Color {
        switch theme {
        case "Dark": return Color.white
        case "Sepia": return Color(red: 95/255, green: 75/255, blue: 50/255)
        case "Paper": return Color(red: 50/255, green: 50/255, blue: 50/255)
        default: return Color.black
        }
    }

    private var selectedFont: Font {
        switch fontName {
        case "Serif": return .custom("Georgia", size: fontSize)
        case "Monospace": return .custom("Courier", size: fontSize)
        case "Avenir": return .custom("Avenir-Medium", size: fontSize)
        case "Charter": return .custom("Charter-Roman", size: fontSize)
        default: return .system(size: fontSize)
        }
    }
}
