import Foundation

struct SavedForLaterItem: Identifiable, Codable {
    var id = UUID()
    let url: String
    let title: String
    let savedAt: Date
}

class SaveForLaterManager: ObservableObject {
    @Published var items: [SavedForLaterItem] = [] {
        didSet { save() }
    }

    private let key = "save_for_later_items"

    init() {
        load()
    }

    func add(url: String, title: String) {
        guard !url.isEmpty else { return }
        if items.contains(where: { $0.url == url }) { return }
        items.insert(SavedForLaterItem(url: url, title: title, savedAt: Date()), at: 0)
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
    }

    func clear() {
        items.removeAll()
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SavedForLaterItem].self, from: data)
        else { return }
        items = decoded
    }
}
