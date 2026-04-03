import Foundation
import SwiftUI

struct Collection: Identifiable, Codable {
    var id = UUID()
    var name: String
    var color: String // Hex string
    var sfSymbol: String
    var urls: [String]
    var createdAt: Date = Date()
}

class CollectionsManager: ObservableObject {
    @Published var collections: [Collection] = [] {
        didSet { saveCollections() }
    }

    private let collectionsKey = "browser_collections"

    init() {
        loadCollections()
    }

    func addCollection(name: String, color: String, sfSymbol: String, urls: [String]) {
        let newCollection = Collection(name: name, color: color, sfSymbol: sfSymbol, urls: urls)
        collections.append(newCollection)
    }

    func deleteCollection(id: UUID) {
        collections.removeAll { $0.id == id }
    }

    private func saveCollections() {
        if let encoded = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(encoded, forKey: collectionsKey)
        }
    }

    private func loadCollections() {
        if let data = UserDefaults.standard.data(forKey: collectionsKey),
           let decoded = try? JSONDecoder().decode([Collection].self, from: data) {
            collections = decoded
        }
    }
}

