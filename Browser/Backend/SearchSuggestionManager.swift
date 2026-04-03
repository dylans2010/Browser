import Foundation
import Combine

class SearchSuggestionManager: ObservableObject {
    @Published var suggestions: [String] = []
    private var cancellables = Set<AnyCancellable>()

    func updateSuggestions(for query: String, history: [HistoryItem], favorites: [FavoriteItem], learningModel: SearchLearningModel) async {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.suggestions = []
            }
            return
        }

        let trimmedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Sources:
        // 1. History
        let historySuggestions = history
            .filter { $0.title.lowercased().contains(trimmedQuery) || $0.url.lowercased().contains(trimmedQuery) }
            .map { $0.title }

        // 2. Favorites
        let favoriteSuggestions = favorites
            .filter { $0.title.lowercased().contains(trimmedQuery) || $0.url.lowercased().contains(trimmedQuery) }
            .map { $0.title }

        // 3. Learning Model (frequency-based)
        let learnedSuggestions = learningModel.getSuggestions(for: query)

        // 4. Remote Suggestions (from the existing service logic)
        let remoteSuggestions = await fetchRemoteSuggestions(for: query)

        DispatchQueue.main.async {
            var combinedSuggestions = (historySuggestions + favoriteSuggestions + learnedSuggestions + remoteSuggestions)

            // Deduplicate and filter out the exact query
            var seen = Set<String>()
            combinedSuggestions = combinedSuggestions.filter {
                let low = $0.lowercased()
                if seen.contains(low) || low == trimmedQuery {
                    return false
                }
                seen.insert(low)
                return true
            }

            self.suggestions = Array(combinedSuggestions.prefix(10))
        }
    }

    private func fetchRemoteSuggestions(for query: String) async -> [String] {
        let urlString = "https://suggestqueries.google.com/complete/search?client=firefox&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        guard let url = URL(string: urlString) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [Any],
               json.count > 1,
               let suggestionList = json[1] as? [String] {
                return suggestionList
            }
        } catch {
            print("Error fetching remote suggestions: \(error)")
        }
        return []
    }
}
