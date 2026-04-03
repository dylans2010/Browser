import Foundation

class SearchSuggestionService: ObservableObject {
    @Published var suggestions: [String] = []

    func fetchSuggestions(for query: String) async {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.suggestions = []
            }
            return
        }

        let urlString = "https://suggestqueries.google.com/complete/search?client=firefox&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [Any],
               json.count > 1,
               let suggestionList = json[1] as? [String] {
                DispatchQueue.main.async {
                    self.suggestions = suggestionList
                }
            }
        } catch {
            print("Error fetching suggestions: \(error)")
        }
    }
}
