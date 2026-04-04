import Foundation

enum ToolCategory: String, Codable, CaseIterable {
    case navigation = "Navigation"
    case page = "Page"
    case tabs = "Tabs"
    case data = "Data"
    case media = "Media"
    case privacy = "Privacy"
    case ai = "AI"
    case advanced = "Advanced"
    case favorites = "Favorites"
    case downloads = "Downloads"
    case history = "History"
    case collections = "Collections"
}

enum ToolActionType: String, Codable, CaseIterable {
    // Navigation
    case back
    case forward
    case reload
    case hardRefresh
    case stopLoading
    // Page
    case findOnPage
    case scrollToTop
    case scrollToBottom
    case readerMode
    case toggleDarkMode
    // Tabs
    case newTab
    case newPrivateTab
    case duplicateTab
    case closeThisTab
    case closeAllTabs
    case closeOtherTabs
    case viewAllTabs
    case viewPrivateTabs
    // Data
    case viewPageSource
    case copyURL
    case copyPageTitle
    case saveAsPDF
    case savePageOffline
    case share
    // Media
    case pictureInPicture
    case muteTab
    case unmuteTab
    case listenToPage
    // Privacy
    case toggleJavaScript
    case clearCookiesForSite
    case clearCacheForSite
    case toggleAdBlocker
    // AI
    case summarizePage
    case askThePage
    case keyTakeaways
    case toneAnalysis
    case extractTasks
    // Advanced
    case inspectElement
    case viewNetworkLogs
    case switchUserAgent
    // Favorites
    case favoritePage
    case removeFromFavorites
    // Downloads
    case viewDownloads
    // History
    case viewHistory
    // Collections
    case addToCollection
    // New Tools
    case addNote
    case hideElements
    case revertToOriginal
    case websiteStyling
    case browserAssistant
    // UI
    case divider
}

struct ToolItem: Identifiable, Codable {
    var id = UUID()
    let title: String
    let icon: String // SF Symbol name
    var isEnabled: Bool
    let actionType: ToolActionType
    var category: ToolCategory
    var requiresWebView: Bool
    var toggleState: Bool?

    init(
        title: String,
        icon: String,
        isEnabled: Bool = true,
        actionType: ToolActionType,
        category: ToolCategory = .page,
        requiresWebView: Bool = false,
        toggleState: Bool? = nil
    ) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.actionType = actionType
        self.category = category
        self.requiresWebView = requiresWebView
        self.toggleState = toggleState
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        icon = try container.decode(String.self, forKey: .icon)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        actionType = try container.decode(ToolActionType.self, forKey: .actionType)
        category = try container.decodeIfPresent(ToolCategory.self, forKey: .category) ?? .page
        requiresWebView = try container.decodeIfPresent(Bool.self, forKey: .requiresWebView) ?? false
        toggleState = try container.decodeIfPresent(Bool.self, forKey: .toggleState)
    }
}
