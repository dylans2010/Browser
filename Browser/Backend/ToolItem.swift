import Foundation

enum ToolActionType: String, Codable, CaseIterable {
    case findOnPage
    case forward
    case reload
    case share
    case newTab
    case newPrivateTab
    case closeThisTab
    case closeAllTabs
    case viewHistory
    case viewDownloads
    case toggleJavaScript
    case scrollToTop
    case favoritePage
    case summarizePage
    case askThePage
    case readerMode
    case listenToPage
    case extractTasks
    case viewAllTabs
    case viewPrivateTabs
    case keyTakeaways
    case toneAnalysis
}

struct ToolItem: Identifiable, Codable {
    var id = UUID()
    let title: String
    let icon: String // SF Symbol name
    var isEnabled: Bool = true
    let actionType: ToolActionType
}
