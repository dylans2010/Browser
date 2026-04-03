import Foundation
import Combine

class ToolbarManager: ObservableObject {
    @Published var availableTools: [ToolItem] = [
        ToolItem(title: "Find On Page", icon: "doc.text.magnifyingglass", actionType: .findOnPage),
        ToolItem(title: "Forward", icon: "chevron.right", actionType: .forward),
        ToolItem(title: "Reload", icon: "arrow.clockwise", actionType: .reload),
        ToolItem(title: "Share", icon: "square.and.arrow.up", actionType: .share),
        ToolItem(title: "New Tab", icon: "plus.circle", actionType: .newTab),
        ToolItem(title: "New Private Tab", icon: "eye.slash", actionType: .newPrivateTab),
        ToolItem(title: "Close This Tab", icon: "xmark.circle", actionType: .closeThisTab),
        ToolItem(title: "Close All Tabs", icon: "trash", actionType: .closeAllTabs),
        ToolItem(title: "View History", icon: "clock", actionType: .viewHistory),
        ToolItem(title: "View Downloads", icon: "arrow.down.circle", actionType: .viewDownloads),
        ToolItem(title: "Disable JavaScript", icon: "script.badge.ellipsis", actionType: .toggleJavaScript),
        ToolItem(title: "Scroll To Top", icon: "arrow.up.circle", actionType: .scrollToTop),
        ToolItem(title: "Favorite Page", icon: "star", actionType: .favoritePage),
        ToolItem(title: "Summarize Page", icon: "doc.text.magnifyingglass", actionType: .summarizePage),
        ToolItem(title: "Ask the Page", icon: "bubble.left.and.bubble.right", actionType: .askThePage),
        ToolItem(title: "Reader Mode", icon: "text.justify.left", actionType: .readerMode),
        ToolItem(title: "Listen to Page", icon: "speaker.wave.2", actionType: .listenToPage),
        ToolItem(title: "Extract Tasks", icon: "checklist", actionType: .extractTasks),
        ToolItem(title: "View All Tabs", icon: "square.on.square", actionType: .viewAllTabs),
        ToolItem(title: "View Private Tabs", icon: "eye.slash.fill", actionType: .viewPrivateTabs),
        ToolItem(title: "Key Takeaways", icon: "list.bullet.rectangle", actionType: .keyTakeaways),
        ToolItem(title: "Tone Analysis", icon: "waveform.path.ecg", actionType: .toneAnalysis)
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
}
