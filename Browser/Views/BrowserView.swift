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
    @State private var showInspectElement = false
    @State private var showPageSource = false
    @State private var showAddToCollection = false
    @State private var showPDFShare = false
    @State private var showWebsiteStyle = false

    // Data for sheets
    @State private var aiResultTitle = ""
    @State private var aiResultContent = ""
    @State private var aiResultLoading = false
    @State private var inspectDOMInfo: InspectElementTool.DOMInfo? = nil
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
                VStack {
                    Spacer().frame(height: 100)
                    SearchSuggestionsView(suggestionManager: suggestionManager, query: browserViewModel.urlString) { selected in
                        browserViewModel.urlString = selected
                        loadURL()
                        isAddressBarFocused = false
                    }
                    Spacer()
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
        .sheet(isPresented: $showInspectElement) {
            if let info = inspectDOMInfo { InspectElementView(domInfo: info) }
        }
        .sheet(isPresented: $showPageSource) { ViewPageSourceView(source: pageSourceContent) }
        .sheet(isPresented: $showAddToCollection) { addToCollectionSheet }
        .sheet(isPresented: $showWebsiteStyle) {
            if let domain = browserViewModel.activeTab?.url?.host { WebsiteStyleView(domain: domain) }
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

    private var toolbarMenuItems: some View {
        Group {
            // New Tools
            Group {
                Button(action: { showAddNote = true }) {
                    Label("Add Note", systemImage: "note.text.badge.plus")
                }
                Button(action: {
                    if let webView = browserViewModel.activeTab?.webView {
                        HideElementsTool.execute(webView: webView, elementHiderManager: elementHiderManager)
                    }
                }) {
                    Label("Hide Elements", systemImage: "eye.slash")
                }
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
                Button(action: { showInspectElement = true }) { Label("Inspect Element", systemImage: "hammer") }
                Button(action: { showNetworkLogs = true }) { Label("Network Logs", systemImage: "network") }
            }

            Divider()

            // General
            Group {
                Button(action: { showAllTabs = true }) { Label("All Tabs", systemImage: "square.on.square") }
                Button(action: { showDownloads = true }) { Label("Downloads", systemImage: "arrow.down.circle") }
                Button(action: { showHistory = true }) { Label("History", systemImage: "clock") }
                Button(action: { showSettings = true }) { Label("Settings", systemImage: "gear") }
            }
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
