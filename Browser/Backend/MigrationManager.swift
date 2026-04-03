import Foundation
import SwiftUI
import UniformTypeIdentifiers

@available(iOS 16.0, *)
class MigrationManager: ObservableObject {
    static let shared = MigrationManager()

    struct ExportData: Codable {
        let history: [HistoryItem]
        let favorites: [FavoriteItem]
        let collections: [Collection]
    }

    func exportToJSON() -> URL? {
        let historyData = loadHistory()
        let favoritesData = loadFavorites()
        let collectionsData = loadCollections()

        let export = ExportData(history: historyData, favorites: favoritesData, collections: collectionsData)

        do {
            let encoded = try JSONEncoder().encode(export)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("BrowserBackup.json")
            try encoded.write(to: tempURL)
            return tempURL
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }

    func importFromJSON(at url: URL, historyManager: HistoryManager, favoritesManager: FavoritesManager, collectionsManager: CollectionsManager) {
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(ExportData.self, from: data)

            DispatchQueue.main.async {
                historyManager.history = decoded.history
                favoritesManager.favorites = decoded.favorites
                collectionsManager.collections = decoded.collections
            }
        } catch {
            print("Import failed: \(error)")
        }
    }

    private func loadHistory() -> [HistoryItem] {
        if let data = UserDefaults.standard.data(forKey: "browser_history"),
           let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            return decoded
        }
        return []
    }

    private func loadFavorites() -> [FavoriteItem] {
        if let data = UserDefaults.standard.data(forKey: "browser_favorites"),
           let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) {
            return decoded
        }
        return []
    }

    private func loadCollections() -> [Collection] {
        if let data = UserDefaults.standard.data(forKey: "browser_collections"),
           let decoded = try? JSONDecoder().decode([Collection].self, from: data) {
            return decoded
        }
        return []
    }
}
