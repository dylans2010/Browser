import Foundation
import Combine

class ToolbarManager: ObservableObject {
    @Published var availableTools: [ToolItem] = [
        // Navigation
        ToolItem(title: "Back", icon: "chevron.left", actionType: .back, category: .navigation, requiresWebView: true),
        ToolItem(title: "Forward", icon: "chevron.right", actionType: .forward, category: .navigation, requiresWebView: true),
        ToolItem(title: "Reload", icon: "arrow.clockwise", actionType: .reload, category: .navigation, requiresWebView: true),
        ToolItem(title: "Hard Refresh", icon: "arrow.clockwise.circle", actionType: .hardRefresh, category: .navigation, requiresWebView: true),
        ToolItem(title: "Stop Loading", icon: "xmark.circle", actionType: .stopLoading, category: .navigation, requiresWebView: true),
        // Page
        ToolItem(title: "Find On Page", icon: "doc.text.magnifyingglass", actionType: .findOnPage, category: .page, requiresWebView: true),
        ToolItem(title: "Scroll To Top", icon: "arrow.up.to.line", actionType: .scrollToTop, category: .page, requiresWebView: true),
        ToolItem(title: "Scroll To Bottom", icon: "arrow.down.to.line", actionType: .scrollToBottom, category: .page, requiresWebView: true),
        ToolItem(title: "Reader Mode", icon: "text.justify.left", actionType: .readerMode, category: .page, requiresWebView: true),
        ToolItem(title: "Toggle Dark Mode", icon: "moon.fill", actionType: .toggleDarkMode, category: .page, requiresWebView: true),
        // Tabs
        ToolItem(title: "New Tab", icon: "plus.circle", actionType: .newTab, category: .tabs),
        ToolItem(title: "New Private Tab", icon: "eye.slash", actionType: .newPrivateTab, category: .tabs),
        ToolItem(title: "Duplicate Tab", icon: "doc.on.doc", actionType: .duplicateTab, category: .tabs),
        ToolItem(title: "Close This Tab", icon: "xmark.circle", actionType: .closeThisTab, category: .tabs),
        ToolItem(title: "Close All Tabs", icon: "trash", actionType: .closeAllTabs, category: .tabs),
        ToolItem(title: "Close Other Tabs", icon: "square.stack", actionType: .closeOtherTabs, category: .tabs),
        ToolItem(title: "View All Tabs", icon: "square.on.square", actionType: .viewAllTabs, category: .tabs),
        ToolItem(title: "View Private Tabs", icon: "eye.slash.fill", actionType: .viewPrivateTabs, category: .tabs),
        // Data
        ToolItem(title: "View Page Source", icon: "chevron.left.forwardslash.chevron.right", actionType: .viewPageSource, category: .data, requiresWebView: true),
        ToolItem(title: "Copy URL", icon: "link", actionType: .copyURL, category: .data),
        ToolItem(title: "Copy Page Title", icon: "doc.on.clipboard", actionType: .copyPageTitle, category: .data),
        ToolItem(title: "Save as PDF", icon: "arrow.down.doc", actionType: .saveAsPDF, category: .data, requiresWebView: true),
        ToolItem(title: "Save Page Offline", icon: "icloud.and.arrow.down", actionType: .savePageOffline, category: .data, requiresWebView: true),
        ToolItem(title: "Share", icon: "square.and.arrow.up", actionType: .share, category: .data),
        // Media
        ToolItem(title: "Picture in Picture", icon: "pip", actionType: .pictureInPicture, category: .media, requiresWebView: true),
        ToolItem(title: "Mute Tab", icon: "speaker.slash", actionType: .muteTab, category: .media, requiresWebView: true),
        ToolItem(title: "Unmute Tab", icon: "speaker.wave.2", actionType: .unmuteTab, category: .media, requiresWebView: true),
        ToolItem(title: "Listen to Page", icon: "waveform", actionType: .listenToPage, category: .media, requiresWebView: true),
        // Privacy
        ToolItem(title: "Toggle JavaScript", icon: "j.square", actionType: .toggleJavaScript, category: .privacy, requiresWebView: true),
        ToolItem(title: "Clear Cookies for Site", icon: "trash.circle", actionType: .clearCookiesForSite, category: .privacy, requiresWebView: true),
        ToolItem(title: "Clear Cache for Site", icon: "arrow.counterclockwise", actionType: .clearCacheForSite, category: .privacy, requiresWebView: true),
        ToolItem(title: "Toggle Ad Blocker", icon: "shield", actionType: .toggleAdBlocker, category: .privacy),
        // AI
        ToolItem(title: "Summarize Page", icon: "text.magnifyingglass", actionType: .summarizePage, category: .ai, requiresWebView: true),
        ToolItem(title: "Ask the Page", icon: "bubble.left.and.bubble.right", actionType: .askThePage, category: .ai, requiresWebView: true),
        ToolItem(title: "Key Takeaways", icon: "list.bullet.rectangle", actionType: .keyTakeaways, category: .ai, requiresWebView: true),
        ToolItem(title: "Tone Analysis", icon: "waveform.path.ecg", actionType: .toneAnalysis, category: .ai, requiresWebView: true),
        ToolItem(title: "Extract Tasks", icon: "checklist", actionType: .extractTasks, category: .ai, requiresWebView: true),
        // Advanced
        ToolItem(title: "Developer Tools", icon: "hammer", actionType: .inspectElement, category: .advanced, requiresWebView: true),
        ToolItem(title: "View Network Logs", icon: "network", actionType: .viewNetworkLogs, category: .advanced),
        ToolItem(title: "Switch User Agent", icon: "desktopcomputer", actionType: .switchUserAgent, category: .advanced, requiresWebView: true),
        // Favorites
        ToolItem(title: "Add to Favorites", icon: "star", actionType: .favoritePage, category: .favorites),
        ToolItem(title: "Remove from Favorites", icon: "star.slash", actionType: .removeFromFavorites, category: .favorites),
        // Downloads
        ToolItem(title: "View Downloads", icon: "arrow.down.circle", actionType: .viewDownloads, category: .downloads),
        // History
        ToolItem(title: "View History", icon: "clock", actionType: .viewHistory, category: .history),
        // Collections
        ToolItem(title: "Add to Collection", icon: "folder.badge.plus", actionType: .addToCollection, category: .collections),
        // New Tools
        ToolItem(title: "Add Note", icon: "note.text.badge.plus", actionType: .addNote, category: .page, requiresWebView: true),
        ToolItem(title: "Hide Elements", icon: "eye.slash", actionType: .hideElements, category: .advanced, requiresWebView: true),
        ToolItem(title: "Revert To Original", icon: "arrow.counterclockwise.circle", actionType: .revertToOriginal, category: .advanced, requiresWebView: true),
        ToolItem(title: "Website Styling", icon: "paintpalette", actionType: .websiteStyling, category: .advanced, requiresWebView: true)
    ]

    @Published var visibleToolIDs: [UUID] = []

    private let toolsKey = "toolbar_items"

    init() {
        loadTools()
    }

    func saveTools() {
        if let encoded = try? JSONEncoder().encode(availableTools) {
            UserDefaults.standard.set(encoded, forKey: toolsKey)
        }
    }

    private func loadTools() {
        if let data = UserDefaults.standard.data(forKey: toolsKey),
           let decoded = try? JSONDecoder().decode([ToolItem].self, from: data) {
            availableTools = decoded
        }
        visibleToolIDs = availableTools.filter { $0.isEnabled }.map { $0.id }
    }

    func toggleToolVisibility(id: UUID) {
        if let index = availableTools.firstIndex(where: { $0.id == id }) {
            availableTools[index].isEnabled.toggle()
            saveTools()
            visibleToolIDs = availableTools.filter { $0.isEnabled }.map { $0.id }
        }
    }

    func reorderTools(from: IndexSet, to: Int) {
        availableTools.move(fromOffsets: from, toOffset: to)
        saveTools()
        visibleToolIDs = availableTools.filter { $0.isEnabled }.map { $0.id }
    }

    func addDivider() {
        let divider = ToolItem(title: "Divider", icon: "minus", actionType: .divider)
        availableTools.append(divider)
        saveTools()
        visibleToolIDs = availableTools.filter { $0.isEnabled }.map { $0.id }
    }

    func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: toolsKey)
        loadTools()
    }
}
