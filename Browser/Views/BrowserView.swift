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
    @AppStorage("Movable URL-Bar") var urlBarMovable = false
    @AppStorage("OFFSET_X") var offsetX: Double = 0
    @AppStorage("OFFSET_Y") var offsetY: Double = 0
    
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

    @State private var showFindOnPage = false
    @State private var findQuery = ""

    var offset: CGSize { CGSize(width: offsetX, height: offsetY) }

    var body: some View {
        ZStack {
            mainContentView
            
            if !hideURLbar {
                addressBarOverlay
            }

            if showFindOnPage {
                findOnPageOverlay
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showDownloads) { DownloadsView() }
        .sheet(isPresented: $showHistory) { HistoryView(historyManager: historyManager) }
        .sheet(isPresented: $showAllTabs) { AllTabsView(viewModel: browserViewModel) }
        .sheet(isPresented: $showPrivateTabs) { PrivateTabsView(viewModel: browserViewModel) }
        .sheet(isPresented: $showSummary) { SummaryView(viewModel: browserViewModel).environmentObject(aiConfig) }
        .sheet(isPresented: $showAIChat) { AIChatView(viewModel: browserViewModel).environmentObject(aiConfig) }
        .sheet(isPresented: $showReaderMode) { ReaderModeView(viewModel: browserViewModel) }
        .sheet(isPresented: $showNotes) { NotesView(notesManager: notesManager) }
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

            TextField("Search or enter URL", text: $browserViewModel.urlString, onCommit: {
                loadURL()
            })
            .textFieldStyle(.plain)
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
        .offset(offset)
        .gesture(urlBarMovable ? DragGesture().onChanged { g in
            offsetX = g.translation.width
            offsetY = g.translation.height
        } : nil)
    }

    private var addressBarBackground: some View {
        Group {
            if addressBarStyle == "Liquid Glass" {
                RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)
            } else if addressBarStyle == "Modern" {
                RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1))
            } else {
                RoundedRectangle(cornerRadius: 0).stroke(Color.gray, lineWidth: 1)
            }
        }
    }

    private var addressBarWrapperBackground: some View {
        Group {
            if addressBarStyle == "Liquid Glass" {
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

    private var findOnPageOverlay: some View {
        VStack {
            HStack {
                TextField("Find on page", text: $findQuery, onCommit: {
                    if let webView = browserViewModel.activeTab?.webView {
                        FindOnPageTool.execute(in: webView, query: findQuery)
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)

                Button("Done") {
                    if let webView = browserViewModel.activeTab?.webView {
                        FindOnPageTool.clear(in: webView)
                    }
                    showFindOnPage = false
                    findQuery = ""
                }
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(10)
            .padding()
            Spacer()
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
        }
    }
}
