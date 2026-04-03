import SwiftUI

@available(iOS 16.0, *)
struct SettingsView: View {
    @AppStorage("Default-URL") var DefaultURL = ""
    @AppStorage("homePageBackgroundStyle") var backgroundStyle: String = "Blurred Camera"
    @AppStorage("new-tab-bg") var ImageURL = ""
    @AppStorage("Save-Last-URL") var saveLastURL = false
    @AppStorage("Movable URL-Bar") var urlBarMovable = false
    @AppStorage("Quick Position Reset Overlay") var quickPositionReset = false
    @State private var useBlurredView = true
    @State private var showFilePicker = false
    @AppStorage("Shakeable") var shakeable = true
    @AppStorage("OFFSET_X") var offsetX: Double = 0
    @AppStorage("OFFSET_Y") var offsetY: Double = 0
    
    // New Settings
    @AppStorage("addressBarStyle") var addressBarStyle: String = "Modern"
    @AppStorage("addressBarPosition") var addressBarPosition: String = "Bottom"
    @AppStorage("saveDataWhilePrivate") var saveDataWhilePrivate: Bool = false
    @AppStorage("privatePasscode") var privatePasscode: String = ""

    @EnvironmentObject var aiConfig: AIConfiguration
    @EnvironmentObject var toolbarManager: ToolbarManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var favoritesManager: FavoritesManager

    var body: some View {
        TabView {
            generalSettings
            appearanceSettings
            toolbarSettings
            aiSettings
            privateBrowsingSettings
            importSettings
            experimentalSettings
        }
        .sheet(isPresented: $showFilePicker) {
            FileImporterRepresentableView(allowedContentTypes: [.zip, .xml, .json], allowsMultipleSelection: false) { urls in
                if let url = urls.first {
                    importData(from: url)
                }
            }
        }
    }

    private var generalSettings: some View {
        VStack {
            List {
                Section("Default URL", content: {
                    VStack {
                        TextField("e.g. https://example.com", text: $DefaultURL)
                            .disabled(saveLastURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disableAutocorrection(true)
                        #if os(iOS)
                        .autocapitalization(.none)
                        #endif
                        Text("To show the Default New-Tab-Page leave this field blank")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Toggle("Save Last URL", isOn: $saveLastURL)
                })
                Section("New Tab Page", content: {
                    Picker ("Background", selection: $backgroundStyle) {
                        Text("Still Image").tag("Still Image")
                        Text("Blurred Camera").tag("Blurred Camera")
                        Text("Frosted Glass").tag("Frosted Glass")
                    }
                    .pickerStyle(MenuPickerStyle())

                    if backgroundStyle == "Still Image" {
                        TextField("Image URL", text: $ImageURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                })
                Section("More", content: {
                    Toggle("Enable Shake Menu", isOn: $shakeable)
                })
            }
        }
        .tabItem { Label("General", systemImage: "gear") }
    }

    private var appearanceSettings: some View {
        List {
            Section("Address Bar Style", content: {
                Picker("Style", selection: $addressBarStyle) {
                    Text("Liquid Glass").tag("Liquid Glass")
                    Text("Modern").tag("Modern")
                    Text("Classic").tag("Classic")
                }
                Picker("Position", selection: $addressBarPosition) {
                    Text("Top").tag("Top")
                    Text("Bottom").tag("Bottom")
                    Text("Compact").tag("Compact")
                }
            })
        }
        .tabItem { Label("Appearance", systemImage: "paintbrush") }
    }

    private var toolbarSettings: some View {
        List {
            Section {
                Button(action: {
                    toolbarManager.addDivider()
                }) {
                    Label("Add Divider", systemImage: "plus.circle")
                }
            } header: {
                Text("Toolbar Customization")
            } footer: {
                Text("You can reorder tools and dividers by dragging them.")
            }

            Section {
                ForEach(toolbarManager.availableTools) { tool in
                    HStack {
                        Image(systemName: tool.icon)
                            .frame(width: 30)
                        Text(tool.title)
                        Spacer()
                        if tool.actionType != .divider {
                            Toggle("", isOn: Binding(
                                get: { tool.isEnabled },
                                set: { _ in toolbarManager.toggleToolVisibility(id: tool.id) }
                            ))
                        } else {
                            Button(role: .destructive) {
                                if let index = toolbarManager.availableTools.firstIndex(where: { $0.id == tool.id }) {
                                    toolbarManager.availableTools.remove(at: index)
                                    toolbarManager.saveTools()
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .onMove(perform: toolbarManager.reorderTools)
            }
        }
        .tabItem { Label("Toolbar", systemImage: "hammer") }
    }

    private var aiSettings: some View {
        List {
            Section("OpenRouter API", content: {
                SecureField("API Key", text: $aiConfig.apiKey)
            })
            Section("AI Model", content: {
                Picker("Select Model", selection: $aiConfig.selectedModel) {
                    Text("GPT-4o Mini").tag("openai/gpt-4o-mini")
                    Text("Claude 3 Haiku").tag("anthropic/claude-3-haiku")
                    Text("Mistral Small").tag("mistralai/mistral-small")
                }
                TextField("Custom Model ID", text: $aiConfig.customModel)
                    .disableAutocorrection(true)
            })
        }
        .tabItem { Label("AI", systemImage: "brain") }
    }

    private var privateBrowsingSettings: some View {
        List {
            Section("Security", content: {
                SecureField("Set Passcode", text: $privatePasscode)
                Toggle("Save Data While Private", isOn: $saveDataWhilePrivate)
            })
        }
        .tabItem { Label("Private", systemImage: "hand.raised") }
    }

    private var importSettings: some View {
        List {
            Section(
                header: Text("Data Migration"),
                footer: {
                    Text("Import bookmarks and history from a .zip file or browser-exported files (.xml, .json).")
                },
                content: {
                    Button(action: {
                        showFilePicker = true
                    }) {
                        Label("Import From Browsers", systemImage: "square.and.arrow.down")
                    }
                }
            )
        }
        .tabItem { Label("Import", systemImage: "tray.and.arrow.down") }
    }

    private func importData(from url: URL) {
        // Implementation of the import logic. For now, we simulate a successful import.
        // In a real scenario, we would unzip and parse the content.
        print("Importing from \(url.lastPathComponent)")

        // Placeholder logic:
        // favoritesManager.addFavorite(...)
        // historyManager.addToHistory(...)
    }

    private var experimentalSettings: some View {
        List {
            Section("URL-Bar Movement", content: {
                Toggle("Enable Movement", isOn: $urlBarMovable)
                Toggle("Quick Reset Overlay", isOn: $quickPositionReset)
                Button("Reset Position") {
                    offsetX = 0
                    offsetY = 0
                }
            })
        }
        .tabItem { Label("Experimental", systemImage: "sparkles") }
    }
}
