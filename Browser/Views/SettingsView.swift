import SwiftUI

struct SettingsView: View {
    @AppStorage("Default-URL") var DefaultURL = ""
    @AppStorage("Selected NewTab Config") var selectedNewTabConfig = 1
    @AppStorage("new-tab-bg") var ImageURL = ""
    @AppStorage("Use-Image") var useImage = false
    @AppStorage("Save-Last-URL") var saveLastURL = false
    @AppStorage("Movable URL-Bar") var urlBarMovable = false
    @AppStorage("Quick Position Reset Overlay") var quickPositionReset = false
    @State private var useBlurredView = true
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
    
    var body: some View {
        TabView {
            generalSettings
            appearanceSettings
            toolbarSettings
            aiSettings
            privateBrowsingSettings
            experimentalSettings
        }
    }

    private var generalSettings: some View {
        VStack {
            List {
                Section("Default URL") {
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
                }
                Section ("New Tab Page") {
                    Picker ("Background", selection: $selectedNewTabConfig) {
                        Text("Image").tag(0)
                        Text("Blurred Camera").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section ("More") {
                    Toggle("Enable Shake Menu", isOn: $shakeable)
                }
            }
        }
        .tabItem { Label("General", systemImage: "gear") }
    }

    private var appearanceSettings: some View {
        List {
            Section("Address Bar Style") {
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
            }
        }
        .tabItem { Label("Appearance", systemImage: "paintbrush") }
    }

    private var toolbarSettings: some View {
        List {
            Section("Toolbar Customization") {
                ForEach(toolbarManager.availableTools) { tool in
                    HStack {
                        Image(systemName: tool.icon)
                            .frame(width: 30)
                        Text(tool.title)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { tool.isEnabled },
                            set: { _ in toolbarManager.toggleToolVisibility(id: tool.id) }
                        ))
                    }
                }
                .onMove(perform: toolbarManager.reorderTools)
            }
        }
        .tabItem { Label("Toolbar", systemImage: "hammer") }
    }

    private var aiSettings: some View {
        List {
            Section("OpenRouter API") {
                SecureField("API Key", text: $aiConfig.apiKey)
            }
            Section("AI Model") {
                Picker("Select Model", selection: $aiConfig.selectedModel) {
                    Text("GPT-4o Mini").tag("openai/gpt-4o-mini")
                    Text("Claude 3 Haiku").tag("anthropic/claude-3-haiku")
                    Text("Mistral Small").tag("mistralai/mistral-small")
                }
                TextField("Custom Model ID", text: $aiConfig.customModel)
                    .disableAutocorrection(true)
            }
        }
        .tabItem { Label("AI", systemImage: "brain") }
    }

    private var privateBrowsingSettings: some View {
        List {
            Section("Security") {
                SecureField("Set Passcode", text: $privatePasscode)
                Toggle("Save Data While Private", isOn: $saveDataWhilePrivate)
            }
        }
        .tabItem { Label("Private", systemImage: "hand.raised") }
    }

    private var experimentalSettings: some View {
        List {
            Section("URL-Bar Movement") {
                Toggle("Enable Movement", isOn: $urlBarMovable)
                Toggle("Quick Reset Overlay", isOn: $quickPositionReset)
                Button("Reset Position") {
                    offsetX = 0
                    offsetY = 0
                }
            }
        }
        .tabItem { Label("Experimental", systemImage: "sparkles") }
    }
}
