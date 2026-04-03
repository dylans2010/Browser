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
    @State private var showToolsMenu = false
    @State private var showSecurityDetails = false

    // Data for sheets
    @State private var aiResultTitle = ""
    @State private var aiResultContent = ""
    @State private var aiResultLoading = false
    @State private var developerDOMInfo: InspectElementTool.DOMInfo? = nil
    @State private var pageSourceContent = ""
    @State private var pdfURL: URL? = nil
    @State private var securityDetails: SecurityDetails? = nil
    @State private var securityFetcher = SecurityDetailsFetcher()

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
            if isAddressBarFocused && !suggestionManager.suggestions.isEmpty {
                SearchSuggestionsView(suggestionManager: suggestionManager, query: browserViewModel.urlString) { selected in
                    browserViewModel.urlString = selected
                    loadURL()
                    isAddressBarFocused = false
                }
                .zIndex(10)
            }

            // Address bar overlay (Safari-like)
            if browserViewModel.activeTab != nil {
                VStack {
                    Spacer()
                    AddressBarView(
                        viewModel: browserViewModel,
                        isFocused: $isAddressBarFocused,
                        onCommit: { loadURL() },
                        onSecurityTap: { openSecurityDetails() },
                        onShowToolsMenu: { showToolsMenu = true },
                        onShowShare: { ShareTool.execute(url: browserViewModel.urlString) },
                        onShowBookmarks: { showBookmarks = true },
                        onShowTabs: { showAllTabs = true }
                    )
                    .padding(.bottom, 40)
                }
            }
        }
        .findNavigator(isPresented: $showFindOnPage)
        .environmentObject(browserViewModel)
        .environmentObject(elementHiderManager)
        .environmentObject(websiteStyleManager)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showDownloads) {
            DownloadsView()
                .presentationDetents([.fraction(0.3), .medium])
        }
        .sheet(isPresented: $showHistory) { HistoryView(historyManager: historyManager) }
        .sheet(isPresented: $showAllTabs) { AllTabsView(viewModel: browserViewModel) }
        .fullScreenCover(isPresented: $showPrivateTabs) { PrivateTabsView(viewModel: browserViewModel) }
        .sheet(isPresented: $showSummary) { SummaryView(viewModel: browserViewModel).environmentObject(aiConfig) }
        .sheet(isPresented: $showAIChat) { AIChatView(viewModel: browserViewModel).environmentObject(aiConfig) }
        .sheet(isPresented: $showReaderMode) { ReaderModeView(viewModel: browserViewModel) }
        .sheet(isPresented: $showNotes) { NotesAllView() }
        .sheet(isPresented: $showAddNote) { NoteAddView(sourceURL: browserViewModel.urlString) }
        .sheet(isPresented: $showAIResult) { AIResultView(title: aiResultTitle, content: aiResultContent, isLoading: aiResultLoading) }
        .sheet(isPresented: $showNetworkLogs) { NetworkLogsView() }
        .sheet(isPresented: $showDeveloperTools) {
            DeveloperToolsView(domInfo: developerDOMInfo, pageURL: browserViewModel.activeTab?.url?.absoluteString)
        }
        .sheet(isPresented: $showPageSource) { ViewPageSourceView(source: pageSourceContent) }
        .sheet(isPresented: $showAddToCollection) { addToCollectionSheet }
        .sheet(isPresented: $showBookmarks) { BookmarksView() }
        .sheet(isPresented: $showSaveForLater) { SaveForLaterView() }
        .sheet(isPresented: $showToolsMenu) {
            ToolsMenuView(tools: enabledToolbarTools) { tool in
                showToolsMenu = false
                executeTool(tool)
            }
        }
        .sheet(isPresented: $showSecurityDetails) {
            SecurityDetailsView(details: securityDetails)
        }
        .sheet(isPresented: $showWebsiteStyle) {
            if let domain = browserViewModel.activeTab?.url?.host {
                WebsiteStyleView(domain: domain)
            } else {
                Text("Open a website first.")
                    .padding()
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
                NewTabView()
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
            let query = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
            input = "https://www.google.com/search?q=\(query)"
            SearchLearningModel.shared.trackSearch(query: input)
        }
        browserViewModel.urlString = input
        isAddressBarFocused = false
        browserViewModel.loadURLString()
    }

    private var enabledToolbarTools: [ToolItem] {
        toolbarManager.availableTools.filter { $0.isEnabled && $0.actionType != .divider }
    }

    private func openSecurityDetails() {
        showSecurityDetails = true
        guard let url = browserViewModel.activeTab?.url else {
            securityDetails = nil
            return
        }
        securityDetails = SecurityDetails(
            host: url.host ?? "—",
            isSecureConnection: (url.scheme?.lowercased() == "https"),
            transport: url.scheme?.uppercased() ?? "Unknown",
            certificateCommonName: "Loading…",
            issuerSummary: "Loading…",
            validFrom: nil,
            validTo: nil
        )
        securityFetcher.fetch(for: url) { details in
            if let details {
                securityDetails = details
            }
        }
    }

    private func executeTool(_ tool: ToolItem) {
        let webView = browserViewModel.activeTab?.webView
        switch tool.actionType {
        case .back:
            BackTool.execute(viewModel: browserViewModel)
        case .forward:
            if let webView { ForwardTool.execute(in: webView) }
        case .reload:
            if let webView { ReloadTool.execute(in: webView) }
        case .hardRefresh:
            if let webView { HardRefreshTool.execute(in: webView) }
        case .stopLoading:
            if let webView { StopLoadingTool.execute(in: webView) }
        case .findOnPage:
            showFindOnPage = true
        case .scrollToTop:
            if let webView { ScrollToTopTool.execute(in: webView) }
        case .scrollToBottom:
            if let webView { ScrollToBottomTool.execute(in: webView) }
        case .readerMode:
            showReaderMode = true
        case .toggleDarkMode:
            if let webView { DarkModeTool.toggle(in: webView) { _ in } }
        case .newTab:
            NewTabTool.execute(viewModel: browserViewModel)
        case .newPrivateTab:
            NewPrivateTabTool.execute(viewModel: browserViewModel)
        case .duplicateTab:
            DuplicateTabTool.execute(viewModel: browserViewModel)
        case .closeThisTab:
            if let activeId = browserViewModel.activeTabId {
                CloseTabTool.execute(viewModel: browserViewModel, id: activeId)
            }
        case .closeAllTabs:
            CloseAllTabsTool.execute(viewModel: browserViewModel)
        case .closeOtherTabs:
            CloseOtherTabsTool.execute(viewModel: browserViewModel)
        case .viewAllTabs:
            showAllTabs = true
        case .viewPrivateTabs:
            showPrivateTabs = true
        case .viewPageSource:
            if let webView {
                ViewPageSourceTool.execute(webView: webView) { source in
                    pageSourceContent = source
                    showPageSource = true
                }
            }
        case .copyURL:
            CopyURLTool.execute(urlString: browserViewModel.urlString)
        case .copyPageTitle:
            CopyPageTitleTool.execute(title: browserViewModel.activeTab?.title ?? "")
        case .saveAsPDF:
            if let webView {
                SaveAsPDFTool.execute(webView: webView) { _ in }
            }
        case .savePageOffline:
            if let webView {
                SavePageOfflineTool.execute(webView: webView) { _ in }
            }
        case .share:
            ShareTool.execute(url: browserViewModel.urlString)
        case .pictureInPicture:
            if let webView { PictureInPictureTool.execute(in: webView) }
        case .muteTab:
            if let webView { MuteTabTool.mute(in: webView) }
        case .unmuteTab:
            if let webView { MuteTabTool.unmute(in: webView) }
        case .listenToPage:
            ttsManager.speak(browserViewModel.activeTab?.title ?? browserViewModel.urlString)
        case .toggleJavaScript:
            if let webView { JavaScriptToggleTool.execute(in: webView, isEnabled: false) }
        case .clearCookiesForSite:
            if let webView { ClearSiteCookiesTool.execute(for: webView) {} }
        case .clearCacheForSite:
            if let webView { ClearSiteCacheTool.execute(for: webView) {} }
        case .toggleAdBlocker:
            browserViewModel.adBlocker.isEnabled.toggle()
        case .summarizePage:
            showSummary = true
        case .askThePage:
            showAIChat = true
        case .keyTakeaways, .toneAnalysis, .extractTasks:
            showAIChat = true
        case .inspectElement:
            developerDOMInfo = nil
            showDeveloperTools = true
            if let webView {
                InspectElementTool.inspect(webView: webView) { info in
                    developerDOMInfo = info
                }
            }
        case .viewNetworkLogs:
            showNetworkLogs = true
        case .switchUserAgent:
            if let webView { SwitchUserAgentTool.toggle(webView: webView) }
        case .favoritePage:
            FavoriteTool.execute(url: browserViewModel.urlString, title: browserViewModel.activeTab?.title ?? browserViewModel.urlString, favoritesManager: favoritesManager)
        case .removeFromFavorites:
            RemoveFromFavoritesTool.execute(url: browserViewModel.urlString, favoritesManager: favoritesManager)
        case .viewDownloads:
            showDownloads = true
        case .viewHistory:
            showHistory = true
        case .addToCollection:
            showAddToCollection = true
        case .addNote:
            AddNoteTool.execute(url: browserViewModel.urlString, notesManager: notesManager) {
                showNotes = true
            }
        case .hideElements:
            if let webView {
                HideElementsTool.execute(webView: webView, elementHiderManager: elementHiderManager)
            }
        case .revertToOriginal:
            if let webView {
                RevertToOriginalTool.execute(url: browserViewModel.activeTab?.url, elementHiderManager: elementHiderManager, webView: webView)
            }
        case .websiteStyling:
            WebsiteStylingTool.execute {
                showWebsiteStyle = true
            }
        case .divider:
            break
        }
    }

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
