import Foundation

struct FavoriteTool {
    static func execute(url: String, title: String, favoritesManager: FavoritesManager) {
        if favoritesManager.isFavorite(url: url) {
            favoritesManager.removeFavorite(url: url)
        } else {
            favoritesManager.addFavorite(url: url, title: title)
        }
    }
}
