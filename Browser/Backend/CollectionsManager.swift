import Foundation
import SwiftUI

struct Collection: Identifiable, Codable {
    var id = UUID()
    var name: String
    var color: String // Hex string
    var sfSymbol: String
    var urls: [String]
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
