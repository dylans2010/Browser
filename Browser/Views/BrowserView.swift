import SwiftUI
import WebKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@available(iOS 16.0, *)
struct BrowserView: View {
    @StateObject var browserViewModel = BrowserViewModel()
    @StateObject var suggestionService = SearchSuggestionService()
    @EnvironmentObject var aiConfig: AIConfiguration
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var ttsManager: TTSManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var toolbarManager: ToolbarManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var collectionsManager: CollectionsManager

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
    @State private var showNetworkLogs = false
    @State private var showInspectElement = false
    @State private var inspectDOMInfo: InspectElementTool.DOMInfo? = nil
    @State private var showPageSource = false
    @State private var pageSourceContent = ""
    @State private var showAddToCollection = false
    @State private var showPDFShare = false
    @State private var pdfURL: URL? = nil

    @FocusState private var isAddressBarFocused: Bool
    @State private var isEditingAddressBar = false

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

            if isAddressBarFocused && !suggestionService.suggestions.isEmpty {
                suggestionsOverlay
            }

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
        .fullScreenCover(isPresented: $showPrivateTabs) {
            PrivateTabsView(viewModel: browserViewModel)
        }
        .sheet(isPresented: $showSummary) {
            SummaryView(viewModel: browserViewModel)
                .environmentObject(aiConfig)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAIChat) { AIChatView(viewModel: browserViewModel).environmentObject(aiConfig) }
        .sheet(isPresented: $showReaderMode) { ReaderModeView(viewModel: browserViewModel) }
        .sheet(isPresented: $showNotes) { NotesView(notesManager: notesManager) }
        .sheet(isPresented: $showAIResult) {
            AIResultView(title: aiResultTitle, content: aiResultContent, isLoading: aiResultLoading)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showNetworkLogs) {
            NetworkLogsView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showInspectElement) {
            if let info = inspectDOMInfo {
                InspectElementView(domInfo: info)
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showPageSource) {
            ViewPageSourceView(source: pageSourceContent)
        }
        .sheet(isPresented: $showAddToCollection) {
            addToCollectionSheet
        }
        .sheet(isPresented: $showPDFShare) {
#if os(iOS)
            if let url = pdfURL {
                ShareSheet(activityItems: [url])
            }
#endif
        }
        .onAppear {
            browserViewModel.historyManager = historyManager
            browserViewModel.downloadManager = downloadManager
        }
        .onChange(of: downloadManager.showDownloadsUI) { show in
            if show { showDownloads = true; downloadManager.showDownloadsUI = false }
        }
        .onChange(of: browserViewModel.urlString) { newValue in
            if isAddressBarFocused {
                Task {
                    await suggestionService.fetchSuggestions(for: newValue)
                }
            }
        }
        .onChange(of: browserViewModel.activeTabId) { _ in
            isEditingAddressBar = false
            browserViewModel.loadError = nil
        }
    }

    // MARK: - Main Content

    private var mainContentView: some View {
        Group {
            if let activeTab = browserViewModel.activeTab {
                BrowserWebView(webView: activeTab.webView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            } else {
                NewTabPage()
                    .environmentObject(browserViewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        ZStack {
#if os(iOS)
            Color(UIColor.systemBackground).ignoresSafeArea()
#else
            Color(NSColor.windowBackgroundColor).ignoresSafeArea()
#endif

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

                HStack(spacing: 16) {
                    Button {
                        browserViewModel.loadError = nil
                        browserViewModel.reload()
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        browserViewModel.loadError = nil
                    } label: {
                        Text("Dismiss")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Suggestions Overlay

    private var suggestionsOverlay: some View {
        VStack {
            if addressBarPosition == "Top" {
                Spacer().frame(height: 100)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestionService.suggestions, id: \.self) { suggestion in
                        Button(action: {
                            browserViewModel.urlString = suggestion
                            loadURL()
                            isAddressBarFocused = false
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                Text(suggestion)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.primary.opacity(0.001))
                        }
                        Divider()
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(15)
                .padding()
            }
            .frame(maxHeight: 300)

            if addressBarPosition == "Bottom" {
                Spacer().frame(height: 100)
            }
        }
        .zIndex(10)
    }

    // MARK: - Address Bar Overlay

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

    // MARK: - Address Bar View

    private var addressBarView: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: { browserViewModel.goBack() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
            }
            .disabled(!browserViewModel.canGoBack)
            .foregroundColor(.primary)

            // URL input area
            HStack(spacing: 6) {
                // HTTPS lock / insecure indicator
                if !browserViewModel.urlString.isEmpty {
                    Image(systemName: URLFormatter.isSecure(browserViewModel.urlString) ? "lock.fill" : "lock.open")
                        .font(.system(size: 11))
                        .foregroundColor(URLFormatter.isSecure(browserViewModel.urlString) ? .green : .orange)
                }

                // Display formatted URL when not editing; full URL when editing
                if isEditingAddressBar {
#if os(iOS)
                    AddressBarTextField(
                        text: $browserViewModel.urlString,
                        isFocused: $isAddressBarFocused,
                        onCommit: {
                            loadURL()
                            isEditingAddressBar = false
                        }
                    )
                    .frame(height: 18)
#else
                    TextField("Search or enter URL", text: $browserViewModel.urlString, onCommit: {
                        loadURL()
                        isEditingAddressBar = false
                    })
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14))
                    .focused($isAddressBarFocused)
                    .submitLabel(.go)
#endif
                } else {
                    Button(action: {
                        isEditingAddressBar = true
                        isAddressBarFocused = true
                    }) {
                        Text(displayURLText)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Reload / Stop button
                if !browserViewModel.urlString.isEmpty {
                    Button(action: {
                        if browserViewModel.isLoading {
                            browserViewModel.stopLoading()
                        } else {
                            browserViewModel.reload()
                        }
                    }) {
                        Image(systemName: browserViewModel.isLoading ? "xmark" : "arrow.clockwise")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(addressBarBackground)

            // 3-dot menu
            Menu {
                toolbarMenuItems
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(8)
                    .background(Circle().fill(Color.primary.opacity(0.1)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(addressBarWrapperBackground)
        .clipShape(addressBarStyle == "Classic" ? AnyShape(Rectangle()) : AnyShape(Capsule()))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .transition(.move(edge: addressBarPosition == "Top" ? .top : .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hideURLbar)
    }

    /// Text shown in non-editing mode based on the selected display mode.
    private var displayURLText: String {
        if browserViewModel.urlString.isEmpty {
            return "Search or enter URL"
        }
        switch addressBarDisplayMode {
        case "Page Title":
            let title = browserViewModel.activeTab?.title ?? ""
            return title.isEmpty ? URLFormatter.formatted(browserViewModel.urlString) : title
        case "Full Domain":
            return browserViewModel.activeTab?.url?.host ?? URLFormatter.formatted(browserViewModel.urlString)
        default: // "Full URL" → show formatted (compact) URL
            return URLFormatter.formatted(browserViewModel.urlString)
        }
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
            } else if addressBarStyle == "Liquid Glass" {
                RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)
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

    // MARK: - Toolbar Menu (grouped by category)

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

            let enabledTools = toolbarManager.availableTools.filter { $0.isEnabled && $0.actionType != .divider }

            ForEach(ToolCategory.allCases, id: \.self) { category in
                let categoryTools = enabledTools.filter { $0.category == category }
                if !categoryTools.isEmpty {
                    Menu(category.rawValue) {
                        ForEach(categoryTools) { tool in
                            Button {
                                executeTool(tool)
                            } label: {
                                Label(tool.title, systemImage: tool.icon)
                            }
                        }
                    }
                }
            }

            Divider()
            Button("Settings", systemImage: "gear") { showSettings = true }
        }
    }

    // MARK: - Add to Collection Sheet

    private var addToCollectionSheet: some View {
        NavigationView {
            List(collectionsManager.collections) { collection in
                Button {
                    AddToCollectionTool.execute(
                        url: browserViewModel.urlString,
                        collectionId: collection.id,
                        collectionsManager: collectionsManager
                    )
                    showAddToCollection = false
                } label: {
                    HStack {
                        Image(systemName: collection.sfSymbol)
                            .foregroundColor(Color(hex: collection.color))
                        Text(collection.name)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddToCollection = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - UIViewRepresentable Address Bar TextField

#if os(iOS)
struct AddressBarTextField: UIViewRepresentable {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var onCommit: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = "Search or enter URL"
        textField.textAlignment = .center
        textField.returnKeyType = .go
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.keyboardType = .webSearch
        textField.font = UIFont.systemFont(ofSize: 14)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        if isFocused {
            if !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            }
        } else {
            if uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: AddressBarTextField

        init(_ parent: AddressBarTextField) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFocused = true
                textField.selectAll(nil)
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFocused = false
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.text = textField.text ?? ""
            parent.onCommit()
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if let text = textField.text, let textRange = Range(range, in: text) {
                let updatedText = text.replacingCharacters(in: textRange, with: string)
                parent.text = updatedText
            }
            return true
        }
    }
}

/// Thin wrapper to present UIActivityViewController from SwiftUI.
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - URL Loading + Tool Execution

@available(iOS 16.0, *)
extension BrowserView {
    private func loadURL() {
        var input = browserViewModel.urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if input.contains(".") && !input.contains(" ") {
            if !input.contains("://") { input = "https://\(input)" }
        } else {
            let query = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
            input = "https://www.google.com/search?q=\(query)"
        }
        browserViewModel.urlString = input
        isEditingAddressBar = false
        isAddressBarFocused = false
        browserViewModel.loadURLString()
    }

    private func executeTool(_ tool: ToolItem) {
        switch tool.actionType {

        // NAVIGATION
        case .back: browserViewModel.goBack()
        case .forward: browserViewModel.goForward()
        case .reload: browserViewModel.reload()
        case .hardRefresh: browserViewModel.hardRefresh()
        case .stopLoading: browserViewModel.stopLoading()

        // PAGE
        case .findOnPage:
            showFindOnPage.toggle()
        case .scrollToTop:
            if let webView = browserViewModel.activeTab?.webView { ScrollToTopTool.execute(in: webView) }
        case .scrollToBottom:
            if let webView = browserViewModel.activeTab?.webView { ScrollToBottomTool.execute(in: webView) }
        case .readerMode: showReaderMode = true
        case .toggleDarkMode:
            if let webView = browserViewModel.activeTab?.webView {
                DarkModeTool.toggle(in: webView) { _ in }
            }

        // TABS
        case .newTab: browserViewModel.addTab()
        case .newPrivateTab: browserViewModel.addTab(isEphemeral: true)
        case .duplicateTab: DuplicateTabTool.execute(viewModel: browserViewModel)
        case .closeThisTab:
            if let id = browserViewModel.activeTabId { browserViewModel.removeTab(id: id) }
        case .closeAllTabs: CloseAllTabsTool.execute(viewModel: browserViewModel)
        case .closeOtherTabs: CloseOtherTabsTool.execute(viewModel: browserViewModel)
        case .viewAllTabs: showAllTabs = true
        case .viewPrivateTabs: showPrivateTabs = true

        // DATA
        case .viewPageSource:
            if let webView = browserViewModel.activeTab?.webView {
                ViewPageSourceTool.execute(webView: webView) { src in
                    pageSourceContent = src
                    showPageSource = true
                }
            }
        case .copyURL: CopyURLTool.execute(urlString: browserViewModel.urlString)
        case .copyPageTitle:
            CopyPageTitleTool.execute(title: browserViewModel.activeTab?.title ?? "")
        case .saveAsPDF:
            if let webView = browserViewModel.activeTab?.webView {
                SaveAsPDFTool.execute(webView: webView) { url in
                    if let url = url {
                        pdfURL = url
                        showPDFShare = true
                    }
                }
            }
        case .savePageOffline:
            if let webView = browserViewModel.activeTab?.webView {
                SavePageOfflineTool.execute(webView: webView) { url in
                    if let url = url {
                        pdfURL = url
                        showPDFShare = true
                    }
                }
            }
        case .share: ShareTool.execute(url: browserViewModel.urlString)

        // MEDIA
        case .pictureInPicture:
            if let webView = browserViewModel.activeTab?.webView { PictureInPictureTool.execute(in: webView) }
        case .muteTab:
            if let webView = browserViewModel.activeTab?.webView { MuteTabTool.mute(in: webView) }
        case .unmuteTab:
            if let webView = browserViewModel.activeTab?.webView { MuteTabTool.unmute(in: webView) }
        case .listenToPage:
            if ttsManager.isSpeaking {
                ttsManager.stop()
            } else {
                Task {
                    let content = await browserViewModel.extractPageContent()
                    ttsManager.speak(content)
                }
            }

        // PRIVACY
        case .toggleJavaScript:
            if let webView = browserViewModel.activeTab?.webView {
                JavaScriptToggleTool.toggle(in: webView)
            }
        case .clearCookiesForSite:
            if let webView = browserViewModel.activeTab?.webView {
                ClearSiteCookiesTool.execute(for: webView) {}
            }
        case .clearCacheForSite:
            if let webView = browserViewModel.activeTab?.webView {
                ClearSiteCacheTool.execute(for: webView) {}
            }
        case .toggleAdBlocker:
            if let host = browserViewModel.activeTab?.url?.host {
                _ = ToggleAdBlockerTool.toggle(for: host)
            }

        // AI
        case .summarizePage: showSummary = true
        case .askThePage: showAIChat = true
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

        // ADVANCED
        case .inspectElement:
            if let webView = browserViewModel.activeTab?.webView {
                InspectElementTool.inspect(webView: webView) { info in
                    inspectDOMInfo = info
                    showInspectElement = true
                }
            }
        case .viewNetworkLogs: showNetworkLogs = true
        case .switchUserAgent:
            if let webView = browserViewModel.activeTab?.webView {
                SwitchUserAgentTool.toggle(webView: webView)
            }

        // FAVORITES
        case .favoritePage:
            FavoriteTool.execute(url: browserViewModel.urlString, title: browserViewModel.activeTab?.title ?? "Untitled", favoritesManager: favoritesManager)
        case .removeFromFavorites:
            RemoveFromFavoritesTool.execute(url: browserViewModel.urlString, favoritesManager: favoritesManager)

        // DOWNLOADS
        case .viewDownloads: showDownloads = true

        // HISTORY
        case .viewHistory: showHistory = true

        // COLLECTIONS
        case .addToCollection: showAddToCollection = true

        case .divider: break
        }
    }
}
