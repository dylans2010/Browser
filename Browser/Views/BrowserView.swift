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

    // Data for sheets
    @State private var aiResultTitle = ""
    @State private var aiResultContent = ""
    @State private var aiResultLoading = false
    @State private var pageSourceContent = ""
    @State private var pdfURL: URL? = nil

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
                        menuItems: AnyView(toolbarMenuItems)
                    )
                    .padding(.bottom, isAddressBarFocused ? 10 : 40)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .animation(.easeOut(duration: 0.25), value: isAddressBarFocused)
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
        browserViewModel.loadURLString()
    }

    private var toolbarMenuItems: some View {
        Group {
            // New Tools
            Group {
                Button(action: { showAddNote = true }) {
                    Label("Add Note", systemImage: "note.text.badge.plus")
                }
                Button(action: {
                    browserViewModel.enableHideElementsMode(using: elementHiderManager)
                }) {
                    Label("Hide Elements", systemImage: "eye.slash")
                }
                Button(action: {
                    browserViewModel.disableHideElementsMode()
                }) {
                    Label("Stop Hiding Elements", systemImage: "escape")
                }
                .disabled(!browserViewModel.isHideElementsModeEnabled)
                Button(action: {
                    if let webView = browserViewModel.activeTab?.webView {
                        RevertToOriginalTool.execute(url: browserViewModel.activeTab?.url, elementHiderManager: elementHiderManager, webView: webView)
                    }
                }) {
                    Label("Revert To Original", systemImage: "arrow.counterclockwise.circle")
                }
                Button(action: { showWebsiteStyle = true }) {
                    Label("Website Styling", systemImage: "paintpalette")
                }
                Button(action: {
                    if let webView = browserViewModel.activeTab?.webView {
                        TranslateSiteTool.execute(in: webView)
                    }
                }) {
                    Label("Translate Site", systemImage: "translate")
                }
            }

            Divider()

            // Standard Navigation
            Group {
                Button(action: { browserViewModel.goBack() }) {
                    Label("Back", systemImage: "chevron.left")
                }.disabled(!browserViewModel.canGoBack)
                Button(action: { browserViewModel.goForward() }) {
                    Label("Forward", systemImage: "chevron.right")
                }.disabled(!browserViewModel.canGoForward)
                Button(action: { browserViewModel.reload() }) {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
            }

            Divider()

            // AI Features
            Group {
                Button(action: { showSummary = true }) { Label("Summarize Page", systemImage: "text.magnifyingglass") }
                Button(action: { showAIChat = true }) { Label("Ask the Page", systemImage: "bubble.left.and.bubble.right") }
            }

            Divider()

            // Advanced / Tools
            Group {
                Button(action: { showFindOnPage = true }) { Label("Find On Page", systemImage: "doc.text.magnifyingglass") }
                Button(action: { showReaderMode = true }) { Label("Reader Mode", systemImage: "text.justify.left") }
                Button(action: {
                    showDeveloperTools = true
                }) { Label("Developer Tools", systemImage: "hammer") }
                Button(action: { showNetworkLogs = true }) { Label("Network Logs", systemImage: "network") }
            }

            Divider()

            // General
            Group {
                Button(action: { showAllTabs = true }) { Label("All Tabs", systemImage: "square.on.square") }
                Button(action: {
                    favoritesManager.addFavorite(url: browserViewModel.urlString, title: browserViewModel.activeTab?.title ?? browserViewModel.urlString)
                }) { Label("Bookmark This Page", systemImage: "bookmark") }
                Button(action: { showBookmarks = true }) { Label("Bookmarks", systemImage: "book") }
                Button(action: {
                    saveForLaterManager.add(url: browserViewModel.urlString, title: browserViewModel.activeTab?.title ?? browserViewModel.urlString)
                }) { Label("Save For Later", systemImage: "bookmark.circle") }
                Button(action: { showSaveForLater = true }) { Label("Saved For Later", systemImage: "clock.arrow.circlepath") }
                Button(action: { showDownloads = true }) { Label("Downloads", systemImage: "arrow.down.circle") }
                Button(action: { showHistory = true }) { Label("History", systemImage: "clock") }
                Button(action: { showSettings = true }) { Label("Settings", systemImage: "gear") }
            }
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
