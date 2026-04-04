import SwiftUI
import WebKit

@available(iOS 16.0, *)
struct BrowserView: View {
    @StateObject var browserViewModel = BrowserViewModel()
    @StateObject var suggestionManager = SearchSuggestionManager()
    @StateObject var elementHiderManager = ElementHiderManager()
    @StateObject var websiteStyleManager = WebsiteStyleManager()

    @EnvironmentObject var aiConfig: AIConfiguration
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var ttsManager: TTSManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var toolbarManager: ToolbarManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var collectionsManager: CollectionsManager
    @EnvironmentObject var saveForLaterManager: SaveForLaterManager

    @FocusState private var isAddressBarFocused: Bool

    // UI Navigation/Sheet States
    @State private var showSettings = false
    @State private var showDownloads = false
    @State private var showHistory = false
    @State private var showAllTabs = false
    @State private var showPrivateTabs = false
    @State private var showSummary = false
    @State private var showAIChat = false
    @State private var showReaderMode = false
    @State private var showNotes = false
    @State private var showAddNote = false
    @State private var showAIResult = false
    @State private var showFindOnPage = false
    @State private var showNetworkLogs = false
    @State private var showDeveloperTools = false
    @State private var showPageSource = false
    @State private var showAddToCollection = false
    @State private var showPDFShare = false
    @State private var showWebsiteStyle = false
    @State private var showBookmarks = false
    @State private var showSaveForLater = false
    @State private var showLanguageSelection = false
    @State private var showBrowserAssistant = false
    @State private var showAutoNotes = false
    @State private var showPageInfo = false
    @State private var showQRCode = false
    @State private var showPrivacyReport = false

    // Data for sheets
    @State private var aiResultTitle = ""
    @State private var aiResultContent = ""
    @State private var aiResultLoading = false
    @State private var pageSourceContent = ""
    @State private var pdfURL: URL? = nil
    @State private var currentPageInfo: PageInfo? = nil
    @State private var currentPrivacyReport: PrivacyReport? = nil

    var body: some View {
        ZStack {
            mainContentView

            // Loading progress bar
            if browserViewModel.isLoading {
                VStack {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .tint(.blue)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
                .ignoresSafeArea()
            }

            // Error overlay
            if let error = browserViewModel.loadError {
                errorView(message: error)
            }

            // Suggestions overlay
            if isAddressBarFocused {
                VStack(spacing: 0) {
                    SearchSuggestionsView(suggestionManager: suggestionManager, query: browserViewModel.urlString) { selected in
                        browserViewModel.urlString = selected
                        loadURL()
                        isAddressBarFocused = false
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Empty space for the address bar to stay on top of the keyboard
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 80)
                }
                .zIndex(10)
                .transition(.opacity)
            }

            // Address bar overlay (Safari-like)
            VStack {
                Spacer()
                AddressBarView(
                    viewModel: browserViewModel,
                    isFocused: $isAddressBarFocused,
                    onCommit: { loadURL() },
                    onBrowserAssistantTap: { showBrowserAssistant = true },
                    menuItems: AnyView(toolbarMenuItems)
                )
                .padding(.bottom, isAddressBarFocused ? 0 : 40)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isAddressBarFocused)
            .zIndex(20) // Ensure it's above the suggestions

            // Browser Assistant Overlay
            if showBrowserAssistant {
                BrowserAssistantView()
                    .environmentObject(browserViewModel)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .findNavigator(isPresented: $showFindOnPage)
        .environmentObject(browserViewModel)
        .environmentObject(elementHiderManager)
        .environmentObject(websiteStyleManager)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showDownloads) {
            DownloadsView()
                .presentationDetents([.fraction(0.3), .medium])
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(historyManager: historyManager)
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showAllTabs) {
            AllTabsView(viewModel: browserViewModel)
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .fullScreenCover(isPresented: $showPrivateTabs) {
            PrivateTabsView(viewModel: browserViewModel)
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showSummary) {
            SummaryView(viewModel: browserViewModel)
                .presentationDetents([.medium, .large])
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showAIChat) {
            AIChatView(viewModel: browserViewModel)
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showReaderMode) {
            ReaderModeView(viewModel: browserViewModel)
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showNotes) {
            NotesAllView()
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showAddNote) {
            NoteAddView(sourceURL: browserViewModel.urlString)
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showAIResult) {
            AIResultView(title: aiResultTitle, content: aiResultContent, isLoading: aiResultLoading)
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showNetworkLogs) {
            NetworkLogsView()
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showDeveloperTools) {
            Group {
                if let webView = browserViewModel.activeTab?.webView {
                    DeveloperToolsView(webView: webView)
                } else {
                    Text("Open a website first.")
                        .padding()
                }
            }
            .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showPageSource) {
            ViewPageSourceView(source: pageSourceContent)
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showAddToCollection) {
            addToCollectionSheet
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksView()
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showSaveForLater) {
            SaveForLaterView()
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showWebsiteStyle) {
            Group {
                if let domain = websiteStyleManager.normalizedDomain(from: browserViewModel.activeTab?.url?.host) {
                    WebsiteStyleView(domain: domain)
                } else {
                    Text("Open a website first.")
                        .padding()
                }
            }
            .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
        }
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView { targetLanguage in
                if let webView = browserViewModel.activeTab?.webView {
                    TranslateSiteTool.execute(in: webView, targetLanguage: targetLanguage)
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAutoNotes) {
            AutoNotesView(sourceURL: browserViewModel.urlString)
                .injectEnvironment(viewModel: browserViewModel, hider: elementHiderManager, style: websiteStyleManager, ai: aiConfig, notes: notesManager, tts: ttsManager, history: historyManager, downloads: downloadManager, toolbar: toolbarManager, favorites: favoritesManager, collections: collectionsManager, saveLater: saveForLaterManager)
                .presentationDetents([.fraction(0.3), .medium, .large])
        }
        .sheet(isPresented: $showPageInfo) {
            if let info = currentPageInfo {
                PageInfoView(info: info)
            }
        }
        .sheet(isPresented: $showQRCode) {
            QRCodeView(urlString: browserViewModel.urlString)
        }
        .sheet(isPresented: $showPrivacyReport) {
            if let report = currentPrivacyReport {
                PrivacyReportView(report: report)
            }
        }
        .onAppear {
            browserViewModel.historyManager = historyManager
            browserViewModel.downloadManager = downloadManager
            browserViewModel.elementHiderManager = elementHiderManager
            browserViewModel.websiteStyleManager = websiteStyleManager
        }
        .onChange(of: downloadManager.showDownloadsUI) { show in
            if show { showDownloads = true; downloadManager.showDownloadsUI = false }
        }
        .onChange(of: browserViewModel.urlString) { newValue in
            if isAddressBarFocused {
                Task {
                    await suggestionManager.updateSuggestions(for: newValue, history: historyManager.history, favorites: favoritesManager.favorites, learningModel: SearchLearningModel.shared)
                }
            }
        }
    }

    private var mainContentView: some View {
        Group {
            if let activeTab = browserViewModel.activeTab {
                BrowserWebView(webView: activeTab.webView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            } else {
                NewTabView(onSearch: { loadURL() })
                    .environmentObject(browserViewModel)
                    .environmentObject(favoritesManager)
                    .environmentObject(historyManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func errorView(message: String) -> some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 56))
                    .foregroundColor(.secondary)
                Text("Page Failed to Load")
                    .font(.title2.bold())
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Retry") {
                    browserViewModel.loadError = nil
                    browserViewModel.reload()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func loadURL() {
        var input = browserViewModel.urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if input.contains(".") && !input.contains(" ") {
            if !input.contains("://") { input = "https://\(input)" }
        } else {
            let engine = UserDefaults.standard.string(forKey: "searchEngine") ?? "Google"
            let baseURL: String
            switch engine {
            case "Bing": baseURL = "https://www.bing.com/search?q="
            case "DuckDuckGo": baseURL = "https://duckduckgo.com/?q="
            case "Ecosia": baseURL = "https://www.ecosia.org/search?q="
            case "Yahoo": baseURL = "https://search.yahoo.com/search?p="
            default: baseURL = "https://www.google.com/search?q="
            }

            let query = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
            input = baseURL + query
            SearchLearningModel.shared.trackSearch(query: input)
        }
        browserViewModel.urlString = input
        isAddressBarFocused = false

        if let url = URL(string: input) {
            if browserViewModel.activeTab != nil {
                browserViewModel.loadURLString()
            } else {
                browserViewModel.addTab(url: url)
            }
        }
    }

    private var toolbarMenuItems: some View {
        Group {
            // All enabled tools from ToolbarManager
            ForEach(toolbarManager.availableTools.filter { $0.isEnabled && $0.actionType != .divider }) { tool in
                Button(action: {
                    executeTool(tool)
                }) {
                    Label(tool.title, systemImage: tool.icon)
                }
            }
        }
    }

    private func executeTool(_ tool: ToolItem) {
        switch tool.actionType {
        case .back: browserViewModel.goBack()
        case .forward: browserViewModel.goForward()
        case .reload: browserViewModel.reload()
        case .hardRefresh:
            if let webView = browserViewModel.activeTab?.webView {
                HardRefreshTool.execute(in: webView)
            }
        case .stopLoading: browserViewModel.stopLoading()
        case .findOnPage: showFindOnPage = true
        case .scrollToTop:
            if let webView = browserViewModel.activeTab?.webView {
                ScrollToTopTool.execute(in: webView)
            }
        case .scrollToBottom:
            if let webView = browserViewModel.activeTab?.webView {
                ScrollToBottomTool.execute(in: webView)
            }
        case .readerMode: showReaderMode = true
        case .toggleDarkMode:
            if let webView = browserViewModel.activeTab?.webView {
                DarkModeTool.execute(webView: webView)
            }
        case .newTab: browserViewModel.addTab(url: URL(string: "https://www.google.com")!)
        case .newPrivateTab: showPrivateTabs = true
        case .duplicateTab:
             if let activeTab = browserViewModel.activeTab {
                 DuplicateTabTool.execute(viewModel: browserViewModel, tab: activeTab)
             }
        case .closeThisTab:
            if let activeTab = browserViewModel.activeTab {
                browserViewModel.removeTab(id: activeTab.id)
            }
        case .closeAllTabs:
            CloseAllTabsTool.execute(viewModel: browserViewModel)
        case .closeOtherTabs:
            if let activeTab = browserViewModel.activeTab {
                CloseOtherTabsTool.execute(viewModel: browserViewModel, currentTabId: activeTab.id)
            }
        case .viewAllTabs: showAllTabs = true
        case .viewPrivateTabs: showPrivateTabs = true
        case .viewPageSource:
            if let webView = browserViewModel.activeTab?.webView {
                ViewPageSourceTool.execute(webView: webView) { source in
                    pageSourceContent = source
                    showPageSource = true
                }
            }
        case .copyURL:
            let urlToCopy = NoTrackingParameters.clean(browserViewModel.urlString)
            UIPasteboard.general.string = urlToCopy
        case .copyPageTitle:
            if let title = browserViewModel.activeTab?.title {
                UIPasteboard.general.string = title
            }
        case .saveAsPDF:
            if let webView = browserViewModel.activeTab?.webView {
                SaveAsPDFTool.execute(webView: webView) { url in
                    pdfURL = url
                    showPDFShare = true
                }
            }
        case .savePageOffline:
            if let webView = browserViewModel.activeTab?.webView {
                SavePageOfflineTool.execute(webView: webView) { _ in }
            }
        case .share:
            let urlToShare = NoTrackingParameters.clean(browserViewModel.urlString)
            if let url = URL(string: urlToShare) {
                let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(av, animated: true, completion: nil)
                }
            }
        case .pictureInPicture:
            if let webView = browserViewModel.activeTab?.webView {
                PictureInPictureTool.execute(in: webView)
            }
        case .muteTab:
            if let webView = browserViewModel.activeTab?.webView {
                MuteTabTool.execute(webView: webView, mute: true)
            }
        case .unmuteTab:
            if let webView = browserViewModel.activeTab?.webView {
                MuteTabTool.execute(webView: webView, mute: false)
            }
        case .listenToPage:
            if let text = browserViewModel.activeTab?.title { // Simplified for now
                ttsManager.speak(text: text)
            }
        case .toggleJavaScript:
            if let webView = browserViewModel.activeTab?.webView {
                JavaScriptToggleTool.execute(in: webView, isEnabled: true)
            }
        case .clearCookiesForSite:
            if let webView = browserViewModel.activeTab?.webView {
                ClearSiteCookiesTool.execute(for: webView, completion: { })
            }
        case .clearCacheForSite:
            if let webView = browserViewModel.activeTab?.webView {
                ClearSiteCacheTool.execute(for: webView, completion: { })
            }
        case .toggleAdBlocker:
            ToggleAdBlockerTool.execute(for: browserViewModel.activeTab?.url?.host ?? "")
        case .summarizePage: showSummary = true
        case .askThePage: showAIChat = true
        case .keyTakeaways: showSummary = true // Logic reused
        case .toneAnalysis: showSummary = true // Logic reused
        case .extractTasks: showSummary = true // Logic reused
        case .inspectElement: showDeveloperTools = true
        case .viewNetworkLogs: showNetworkLogs = true
        case .switchUserAgent:
            if let webView = browserViewModel.activeTab?.webView {
                SwitchUserAgentTool.execute(webView: webView)
            }
        case .favoritePage:
            favoritesManager.addFavorite(url: browserViewModel.urlString, title: browserViewModel.activeTab?.title ?? browserViewModel.urlString)
        case .removeFromFavorites:
            if let favorite = favoritesManager.favorites.first(where: { $0.url == browserViewModel.urlString }) {
                favoritesManager.removeFavorite(url: favorite.url)
            }
        case .viewDownloads: showDownloads = true
        case .viewHistory: showHistory = true
        case .addToCollection: showAddToCollection = true
        case .addNote: showAddNote = true
        case .hideElements:
            browserViewModel.enableHideElementsMode(using: elementHiderManager)
        case .revertToOriginal:
            if let webView = browserViewModel.activeTab?.webView {
                RevertToOriginalTool.execute(url: browserViewModel.activeTab?.url, elementHiderManager: elementHiderManager, webView: webView)
            }
        case .websiteStyling: showWebsiteStyle = true
        case .browserAssistant: showBrowserAssistant = true
        case .printPage:
            if let webView = browserViewModel.activeTab?.webView {
                PrintPageTool.execute(webView: webView)
            }
        case .zoomIn:
            if let webView = browserViewModel.activeTab?.webView {
                ZoomInTool.execute(webView: webView)
            }
        case .zoomOut:
            if let webView = browserViewModel.activeTab?.webView {
                ZoomOutTool.execute(webView: webView)
            }
        case .resetZoom:
            if let webView = browserViewModel.activeTab?.webView {
                ResetZoomTool.execute(webView: webView)
            }
        case .requestDesktopSite:
            if let webView = browserViewModel.activeTab?.webView {
                RequestDesktopSiteTool.execute(webView: webView)
            }
        case .pageInfo:
            if let webView = browserViewModel.activeTab?.webView {
                PageInfoTool.execute(webView: webView) { info in
                    currentPageInfo = info
                    showPageInfo = true
                }
            }
        case .generateQRCode:
            showQRCode = true
        case .takeScreenshot:
            if let webView = browserViewModel.activeTab?.webView {
                TakeScreenshotTool.execute(webView: webView) { _ in }
            }
        case .increaseTextSize:
            if let webView = browserViewModel.activeTab?.webView {
                IncreaseTextSizeTool.execute(webView: webView)
            }
        case .decreaseTextSize:
            if let webView = browserViewModel.activeTab?.webView {
                DecreaseTextSizeTool.execute(webView: webView)
            }
        case .resetTextSize:
            if let webView = browserViewModel.activeTab?.webView {
                ResetTextSizeTool.execute(webView: webView)
            }
        case .privacyReport:
            currentPrivacyReport = PrivacyReportTool.execute()
            showPrivacyReport = true
        default: break
        }
    }
}

@available(iOS 16.0, *)
extension View {
    func injectEnvironment(
        viewModel: BrowserViewModel,
        hider: ElementHiderManager,
        style: WebsiteStyleManager,
        ai: AIConfiguration,
        notes: NotesManager,
        tts: TTSManager,
        history: HistoryManager,
        downloads: DownloadManager,
        toolbar: ToolbarManager,
        favorites: FavoritesManager,
        collections: CollectionsManager,
        saveLater: SaveForLaterManager
    ) -> some View {
        self.environmentObject(viewModel)
            .environmentObject(hider)
            .environmentObject(style)
            .environmentObject(ai)
            .environmentObject(notes)
            .environmentObject(tts)
            .environmentObject(history)
            .environmentObject(downloads)
            .environmentObject(toolbar)
            .environmentObject(favorites)
            .environmentObject(collections)
            .environmentObject(saveLater)
    }
}

@available(iOS 16.0, *)
extension BrowserView {
    private var addToCollectionSheet: some View {
        NavigationView {
            List(collectionsManager.collections) { collection in
                Button {
                    AddToCollectionTool.execute(url: browserViewModel.urlString, collectionId: collection.id, collectionsManager: collectionsManager)
                    showAddToCollection = false
                } label: {
                    HStack {
                        Image(systemName: collection.sfSymbol).foregroundColor(Color(hex: collection.color))
                        Text(collection.name).foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Add to Collection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showAddToCollection = false } }
            }
        }
    }
}
