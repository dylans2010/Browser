import Foundation

struct RemoveFromFavoritesTool {
    static func execute(url: String, favoritesManager: FavoritesManager) {
        favoritesManager.removeFavorite(url: url)
    }
}
