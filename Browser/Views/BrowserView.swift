import SwiftUI
import WebKit
#if os(macOS)
import AppKit
#endif

struct BrowserView: View {
    @StateObject var browserViewModel = BrowserViewModel()
    @EnvironmentObject var aiConfig: AIConfiguration
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var ttsManager: TTSManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var toolbarManager: ToolbarManager
    @EnvironmentObject var favoritesManager: FavoritesManager

    @AppStorage("addressBarStyle") var addressBarStyle: String = "Modern"
    @AppStorage("addressBarPosition") var addressBarPosition: String = "Bottom"
    @AppStorage("Save-Last-URL") var saveLastURL = false
    @AppStorage("Default-URL") var DefaultURL = ""
    @AppStorage("addressBarDisplayMode") var addressBarDisplayMode: String = "Full URL"
    @AppStorage("addressBarTheme") var addressBarTheme: String = "Glass"
    
    @State private var hideURLbar = false
    @State private var showSettings = false
    @State private var showDownloads = false
    @State private var showHistory = false
    @State private var showAllTabs = false
    @State private var showPrivateTabs = false

    @State private var showSummary = false
    @State private var showAIChat = false
    @State private var showReaderMode = false
    @State private var showNotes = false
    @State private var showAIResult = false
    @State private var aiResultTitle = ""
    @State private var aiResultContent = ""
    @State private var aiResultLoading = false

    @State private var showFindOnPage = false

    var body: some View {
        ZStack {
            mainContentView
            
            if !hideURLbar {
                addressBarOverlay
            }
        }
        .findNavigator(isPresented: $showFindOnPage)
        .environmentObject(browserViewModel)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showDownloads) {
            DownloadsView()
                .presentationDetents([.fraction(0.3), .medium])
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(historyManager: historyManager)
                .environmentObject(browserViewModel)
        }
        .sheet(isPresented: $showAllTabs) { AllTabsView(viewModel: browserViewModel) }
        .sheet(isPresented: $showPrivateTabs) { PrivateTabsView(viewModel: browserViewModel) }
        .sheet(isPresented: $showSummary) {
            SummaryView(viewModel: browserViewModel)
                .environmentObject(aiConfig)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAIChat) { AIChatView(viewModel: browserViewModel).environmentObject(aiConfig) }
        .sheet(isPresented: $showReaderMode) { ReaderModeView(viewModel: browserViewModel) }
        .sheet(isPresented: $showNotes) { NotesView(notesManager: notesManager) }
        .sheet(isPresented: $showAIResult) {
            AIResultView(title: aiResultTitle, content: aiResultContent, isLoading: aiResultLoading)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            browserViewModel.historyManager = historyManager
            browserViewModel.downloadManager = downloadManager
        }
        .onChange(of: downloadManager.showDownloadsUI) { show in
            if show { showDownloads = true; downloadManager.showDownloadsUI = false }
        }
    }

    private var mainContentView: some View {
        Group {
            if let activeTab = browserViewModel.activeTab {
                BrowserWebView(webView: activeTab.webView)
                    .edgesIgnoringSafeArea(.all)
            } else {
                NewTabPage()
                    .environmentObject(browserViewModel)
            }
        }
    }

    private var addressBarOverlay: some View {
        VStack {
            if addressBarPosition == "Top" {
                addressBarView.padding(.top, 40)
                Spacer()
            } else if addressBarPosition == "Bottom" {
                Spacer()
                addressBarView.padding(.bottom, 40)
            } else { // Compact
                HStack {
                    addressBarView.frame(width: 300)
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
    }

    private var addressBarView: some View {
        HStack {
            Button(action: { browserViewModel.goBack() }) {
                Image(systemName: "chevron.left")
            }.disabled(!browserViewModel.canGoBack)

            VStack(spacing: 0) {
                if addressBarDisplayMode != "Full URL" {
                    Text(addressBarDisplayText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                TextField("Search or enter URL", text: $browserViewModel.urlString, onCommit: {
                    loadURL()
                })
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
            }
            .padding(10)
            .background(addressBarBackground)

            Menu {
                toolbarMenuItems
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
            }
        }
        .padding()
        .background(addressBarWrapperBackground)
        .cornerRadius(addressBarStyle == "Classic" ? 0 : 20)
    }

    private var addressBarDisplayText: String {
        guard let activeTab = browserViewModel.activeTab else { return "" }
        if addressBarDisplayMode == "Page Title" {
            return activeTab.title
        } else if addressBarDisplayMode == "Full Domain" {
            return activeTab.url?.host ?? ""
        }
        return ""
    }

    private var addressBarBackground: some View {
        Group {
            if addressBarTheme == "Glass" {
                RoundedRectangle(cornerRadius: 15).fill(.ultraThinMaterial)
            } else if addressBarTheme == "Colorful" {
                RoundedRectangle(cornerRadius: 15).fill(
                    LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]), startPoint: .leading, endPoint: .trailing)
                )
            } else if addressBarStyle == "Modern" {
                RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1))
            } else {
                RoundedRectangle(cornerRadius: 0).stroke(Color.gray, lineWidth: 1)
            }
        }
    }

    private var addressBarWrapperBackground: some View {
        Group {
            if addressBarTheme == "Glass" {
                Color.clear.background(.thinMaterial)
            } else if addressBarTheme == "Colorful" {
                Color.clear.background(Material.ultraThinMaterial)
            } else if addressBarStyle == "Liquid Glass" {
                Color.clear.background(.thinMaterial)
            } else {
                #if os(macOS)
                Color(NSColor.windowBackgroundColor).opacity(0.9)
                #else
                Color(UIColor.systemBackground).opacity(0.9)
                #endif
            }
        }
    }

    private var toolbarMenuItems: some View {
        Group {
            Menu("Address Bar Styles") {
                Picker("Display Mode", selection: $addressBarDisplayMode) {
                    Text("Full URL").tag("Full URL")
                    Text("Page Title").tag("Page Title")
                    Text("Full Domain").tag("Full Domain")
                }
                Picker("Theme", selection: $addressBarTheme) {
                    Text("Standard").tag("Standard")
                    Text("Glass").tag("Glass")
                    Text("Colorful").tag("Colorful")
                }
            }
            Divider()
            ForEach(toolbarManager.availableTools.filter { $0.isEnabled }) { tool in
                Button {
                    executeTool(tool)
                } label: {
                    Label(tool.title, systemImage: tool.icon)
                }
            }
            Divider()
            Button("Settings", systemImage: "gear") { showSettings = true }
        }
    }


    private func loadURL() {
        var input = browserViewModel.urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if input.contains(".") && !input.contains(" ") {
            if !input.contains("://") { input = "https://\(input)" }
        } else {
            let query = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
            input = "https://www.google.com/search?q=\(query)"
        }
        browserViewModel.urlString = input
        browserViewModel.loadURLString()
    }
    
    private func executeTool(_ tool: ToolItem) {
        switch tool.actionType {
        case .findOnPage:
            showFindOnPage.toggle()
        case .forward: browserViewModel.goForward()
        case .reload: browserViewModel.reload()
        case .share: ShareTool.execute(url: browserViewModel.urlString)
        case .newTab: browserViewModel.addTab()
        case .newPrivateTab: browserViewModel.addTab(isEphemeral: true)
        case .closeThisTab: if let id = browserViewModel.activeTabId { browserViewModel.removeTab(id: id) }
        case .closeAllTabs: CloseAllTabsTool.execute(viewModel: browserViewModel)
        case .viewHistory: showHistory = true
        case .viewDownloads: showDownloads = true
        case .toggleJavaScript:
            if let webView = browserViewModel.activeTab?.webView {
                JavaScriptToggleTool.execute(in: webView, isEnabled: false) // Toggles OFF for now
            }
        case .scrollToTop: if let webView = browserViewModel.activeTab?.webView { ScrollToTopTool.execute(in: webView) }
        case .favoritePage:
            FavoriteTool.execute(url: browserViewModel.urlString, title: browserViewModel.activeTab?.title ?? "Untitled", favoritesManager: favoritesManager)
        case .summarizePage: showSummary = true
        case .askThePage: showAIChat = true
        case .readerMode: showReaderMode = true
        case .listenToPage:
            if ttsManager.isSpeaking {
                ttsManager.stop()
            } else {
                Task {
                    let content = await browserViewModel.extractPageContent()
                    ttsManager.speak(content)
                }
            }
        case .extractTasks:
            Task {
                let content = await browserViewModel.extractPageContent()
                do {
                    let tasks = try await TaskExtractor.shared.extractTasks(from: content, apiKey: aiConfig.apiKey, model: aiConfig.currentModel)
                    for task in tasks {
                        notesManager.addNote(text: "TASK: \(task.title) - \(task.description)", sourceURL: browserViewModel.urlString)
                    }
                    showNotes = true
                } catch {
                    print("Task extraction failed")
                }
            }
        case .viewAllTabs: showAllTabs = true
        case .viewPrivateTabs: showPrivateTabs = true
        case .keyTakeaways:
            aiResultTitle = "Key Takeaways"
            aiResultLoading = true
            showAIResult = true
            Task {
                let content = await browserViewModel.extractPageContent()
                do {
                    let result = try await OpenRouterService.shared.fetchCompletion(
                        apiKey: aiConfig.apiKey,
                        model: aiConfig.currentModel,
                        prompt: "Please provide the key takeaways from this content as a bulleted list.",
                        context: content
                    )
                    aiResultContent = result
                    aiResultLoading = false
                } catch {
                    aiResultContent = "Failed to fetch takeaways: \(error.localizedDescription)"
                    aiResultLoading = false
                }
            }
        case .toneAnalysis:
            aiResultTitle = "Tone Analysis"
            aiResultLoading = true
            showAIResult = true
            Task {
                let content = await browserViewModel.extractPageContent()
                do {
                    let result = try await OpenRouterService.shared.fetchCompletion(
                        apiKey: aiConfig.apiKey,
                        model: aiConfig.currentModel,
                        prompt: "Please analyze the tone of this content (e.g., formal, informal, optimistic, critical) and explain why.",
                        context: content
                    )
                    aiResultContent = result
                    aiResultLoading = false
                } catch {
                    aiResultContent = "Failed to fetch analysis: \(error.localizedDescription)"
                    aiResultLoading = false
                }
            }
        }
    }
}
