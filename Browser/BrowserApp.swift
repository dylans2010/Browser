import SwiftUI

@main
struct BrowserApp: App {
    @StateObject private var aiConfig = AIConfiguration()
    @StateObject private var notesManager = NotesManager()
    @StateObject private var ttsManager = TTSManager()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var downloadManager = DownloadManager()
    @StateObject private var toolbarManager = ToolbarManager()
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var collectionsManager = CollectionsManager()

    var body: some Scene {
        WindowGroup {
            if #available(iOS 16.0, *) {
                BrowserView()
                    .environmentObject(aiConfig)
                    .environmentObject(notesManager)
                    .environmentObject(ttsManager)
                    .environmentObject(historyManager)
                    .environmentObject(downloadManager)
                    .environmentObject(toolbarManager)
                    .environmentObject(favoritesManager)
                    .environmentObject(collectionsManager)
            } else {
                Text("Browser requires iOS 16.0 or newer.")
            }
        }
#if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(aiConfig)
                .environmentObject(toolbarManager)
        }
#endif
    }
}
