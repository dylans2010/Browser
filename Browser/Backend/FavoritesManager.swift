import Foundation

struct FavoriteItem: Identifiable, Codable {
    var id = UUID()
    let url: String
    let title: String
}

class FavoritesManager: ObservableObject {
    @Published var favorites: [FavoriteItem] = [] {
        didSet { saveFavorites() }
    }

    private let favoritesKey = "browser_favorites"

    init() {
        loadFavorites()
    }

    func addFavorite(url: String, title: String) {
        if !isFavorite(url: url) {
            let newItem = FavoriteItem(url: url, title: title)
            favorites.append(newItem)
        }
    }

    func removeFavorite(url: String) {
        favorites.removeAll { $0.url == url }
    }

    func isFavorite(url: String) -> Bool {
        favorites.contains { $0.url == url }
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }

    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) {
            favorites = decoded
        }
    }
}
