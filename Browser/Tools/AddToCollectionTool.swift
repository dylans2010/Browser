import Foundation

struct AddToCollectionTool {
    static func execute(url: String, collectionId: UUID, collectionsManager: CollectionsManager) {
        if let index = collectionsManager.collections.firstIndex(where: { $0.id == collectionId }) {
            if !collectionsManager.collections[index].urls.contains(url) {
                collectionsManager.collections[index].urls.append(url)
            }
        }
    }
}
