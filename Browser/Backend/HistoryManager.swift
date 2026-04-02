import Foundation

struct HistoryItem: Identifiable, Codable {
    var id = UUID()
    let url: String
    let title: String
    let date: Date
}

class HistoryManager: ObservableObject {
    @Published var history: [HistoryItem] = [] {
        didSet { saveHistory() }
    }

    private let historyKey = "browser_history"

    init() { loadHistory() }

    func addHistory(url: String, title: String) {
        let newItem = HistoryItem(url: url, title: title, date: Date())
        history.insert(newItem, at: 0)
    }

    func clearHistory() {
        history.removeAll()
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            history = decoded
        }
    }
}
