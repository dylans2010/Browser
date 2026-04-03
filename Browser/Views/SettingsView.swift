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

    // Search Engine
    @AppStorage("searchEngine") var searchEngine: String = "Google"

    // Address Bar Customization
    @AppStorage("addressBarAlignment") var addressBarAlignment: String = "Center"
    @AppStorage("addressBarSize") var addressBarSize: Double = 1.0
    @AppStorage("showSiteIcon") var showSiteIcon: Bool = true
    @AppStorage("showReadTime") var showReadTime: Bool = true
    @AppStorage("addressBarGestures") var addressBarGestures: Bool = true

    // Address Bar Fine Tuning
    @AppStorage("addressBarCornerRadius") var addressBarCornerRadius: Double = 25.0
    @AppStorage("addressBarShadowRadius") var addressBarShadowRadius: Double = 10.0
    @AppStorage("addressBarOpacity") var addressBarOpacity: Double = 1.0
    @AppStorage("addressBarBlur") var addressBarBlur: Double = 1.0 // 0 to 1

    // Startup
    @AppStorage("startupPage") var startupPage: String = "New Tab"

    @EnvironmentObject var aiConfig: AIConfiguration
    @EnvironmentObject var toolbarManager: ToolbarManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var collectionsManager: CollectionsManager

    @State private var showExportSheet = false
    @State private var exportURL: URL?

    private var toolbarDividers: [ToolItem] {
        toolbarManager.availableTools.filter { $0.actionType == .divider }
    }

    var body: some View {
        TabView {
            generalSettings
            appearanceSettings
            toolbarSettings
            aiSettings
            privateBrowsingSettings
            permissionsSettings
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
                Section("Startup Behavior") {
                    Picker("On Launch Open", selection: $startupPage) {
                        Text("New Tab").tag("New Tab")
                        Text("Last Open Page").tag("Last Page")
                    }
                }

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
                    Toggle("Save Last URL (Deprecated)", isOn: $saveLastURL)
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

            Section("Address Bar Customization", content: {
                Picker("Alignment", selection: $addressBarAlignment) {
                    Text("Left").tag("Left")
                    Text("Center").tag("Center")
                    Text("Right").tag("Right")
                }

                VStack(alignment: .leading) {
                    Text("Bar Size: \(Int(addressBarSize * 100))%")
                    Slider(value: $addressBarSize, in: 0.8...1.2, step: 0.05)
                }

                Toggle("Show Site Icon", isOn: $showSiteIcon)
                Toggle("Show Read Time", isOn: $showReadTime)
                Toggle("Enable Swipe Gestures", isOn: $addressBarGestures)

                VStack(alignment: .leading) {
                    Text("Corner Radius: \(Int(addressBarCornerRadius))")
                    Slider(value: $addressBarCornerRadius, in: 0...40, step: 1)
                }

                VStack(alignment: .leading) {
                    Text("Shadow Radius: \(Int(addressBarShadowRadius))")
                    Slider(value: $addressBarShadowRadius, in: 0...30, step: 1)
                }

                VStack(alignment: .leading) {
                    Text("Opacity: \(Int(addressBarOpacity * 100))%")
                    Slider(value: $addressBarOpacity, in: 0.2...1.0, step: 0.05)
                }

                VStack(alignment: .leading) {
                    Text("Blur Intensity: \(Int(addressBarBlur * 100))%")
                    Slider(value: $addressBarBlur, in: 0...1, step: 0.1)
                }
            })

            Section("Search Engine") {
                Picker("Search Engine", selection: $searchEngine) {
                    Text("Google").tag("Google")
                    Text("Bing").tag("Bing")
                    Text("DuckDuckGo").tag("DuckDuckGo")
                    Text("Ecosia").tag("Ecosia")
                    Text("Yahoo").tag("Yahoo")
                }
            }
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
                Button(role: .destructive, action: {
                    toolbarManager.resetToDefaults()
                }) {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
            } header: {
                Text("Toolbar Customization")
            } footer: {
                Text("Toggle tools on/off, drag to reorder. Reset clears saved preferences.")
            }

            ForEach(ToolCategory.allCases, id: \.self) { category in
                let categoryTools = toolbarManager.availableTools.filter { $0.category == category }
                if !categoryTools.isEmpty {
                    Section(category.rawValue) {
                        ForEach(categoryTools) { tool in
                            HStack {
                                Image(systemName: tool.icon)
                                    .frame(width: 30)
                                    .foregroundColor(tool.isEnabled ? .primary : .secondary)
                                Text(tool.title)
                                    .foregroundColor(tool.isEnabled ? .primary : .secondary)
                                Spacer()
                                if tool.actionType != .divider {
                                    Toggle("", isOn: Binding(
                                        get: { tool.isEnabled },
                                        set: { _ in toolbarManager.toggleToolVisibility(id: tool.id) }
                                    ))
                                }
                            }
                        }
                        .onMove(perform: toolbarManager.reorderTools)
                    }
                }
            }

            // Dividers (not in any category)
            if !toolbarDividers.isEmpty {
                Section("Dividers") {
                    ForEach(toolbarDividers) { tool in
                        HStack {
                            Image(systemName: tool.icon).frame(width: 30)
                            Text(tool.title)
                            Spacer()
                            Button(role: .destructive) {
                                if let index = toolbarManager.availableTools.firstIndex(where: { $0.id == tool.id }) {
                                    toolbarManager.availableTools.remove(at: index)
                                    toolbarManager.saveTools()
                                }
                            } label: {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                        }
                    }
                    .onMove(perform: toolbarManager.reorderTools)
                }
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

    private var permissionsSettings: some View {
        AppPermissionsView()
            .tabItem { Label("Permissions", systemImage: "lock.shield") }
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
                footer: Text("Import/Export bookmarks, history, and collections.")
            ) {
                Button(action: {
                    showFilePicker = true
                }) {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }

                Button(action: {
                    if let url = MigrationManager.shared.exportToJSON() {
                        exportURL = url
                        showExportSheet = true
                    }
                }) {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
            }
        }
        .tabItem { Label("Migration", systemImage: "tray.and.arrow.down") }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ActivityView(activityItems: [url])
            }
        }
    }

    private func importData(from url: URL) {
        MigrationManager.shared.importFromJSON(at: url, historyManager: historyManager, favoritesManager: favoritesManager, collectionsManager: collectionsManager)
    }

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
