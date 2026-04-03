import SwiftUI

struct SearchSuggestionsView: View {
    @ObservedObject var suggestionManager: SearchSuggestionManager
    var query: String
    var onSelect: (String) -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestionManager.suggestions, id: \.self) { suggestion in
                        Button(action: {
                            onSelect(suggestion)
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)

                                highlightedText(suggestion, query: query)
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: "arrow.up.left")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.primary.opacity(0.001))
                        }
                        Divider()
                    }
                }
                .padding(.top, 120)
                .padding(.bottom, 160)
            }
        }
    }

    private func highlightedText(_ text: String, query: String) -> some View {
        guard !query.isEmpty else { return Text(text) }

        let lowerText = text.lowercased()
        let lowerQuery = query.lowercased()

        if let range = lowerText.range(of: lowerQuery) {
            let prefix = String(text[..<range.lowerBound])
            let match = String(text[range])
            let suffix = String(text[range.upperBound...])

            return (Text(prefix) + Text(match).bold().foregroundColor(.blue) + Text(suffix))
        } else {
            return Text(text)
        }
    }
}
