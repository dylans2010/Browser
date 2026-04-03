import Foundation
import CoreML

class SearchLearningModel: ObservableObject {
    static let shared = SearchLearningModel()

    @Published var searchFrequencies: [String: Int] = [:]
    private let storageKey = "learned_searches"

    // CoreML related properties (Simulated wrapper)
    private var model: Any? // This would be the actual CoreML model if we had a .mlmodel file

    init() {
        loadData()
        setupModel()
    }

    private func setupModel() {
        // In a real scenario, we would load the .mlmodel here.
        // For this task, we'll simulate the CoreML behavior via pattern-based learning.
        print("SearchLearningModel: CoreML wrapper initialized.")
    }

    func trackSearch(query: String) {
        let trimmedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        searchFrequencies[trimmedQuery, default: 0] += 1
        saveData()

        // Potential online training trigger for a CoreML model would go here
        updateModel(with: trimmedQuery)
    }

    private func updateModel(with query: String) {
        // Simulate CoreML online learning or feature extraction
    }

    func getSuggestions(for query: String) -> [String] {
        let trimmedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        // Combine frequency-based suggestions with predicted completions (simulated)
        let matched = searchFrequencies.keys
            .filter { $0.contains(trimmedQuery) && $0 != trimmedQuery }
            .sorted { (q1, q2) -> Bool in
                let f1 = searchFrequencies[q1] ?? 0
                let f2 = searchFrequencies[q2] ?? 0
                if f1 != f2 {
                    return f1 > f2
                }
                return q1 < q2
            }

        return Array(matched.prefix(5))
    }

    private func saveData() {
        UserDefaults.standard.set(searchFrequencies, forKey: storageKey)
    }

    private func loadData() {
        if let data = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Int] {
            searchFrequencies = data
        }
    }
}
