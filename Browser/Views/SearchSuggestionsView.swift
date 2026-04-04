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
                            HStack(spacing: 15) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .frame(width: 30)

                                highlightedText(suggestion, query: query)
                                    .font(.system(size: 17))
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: "arrow.up.left")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(Color.primary.opacity(0.001))
                        }

                        Divider()
                            .padding(.leading, 65)
                    }
                }
                .padding(.top, 10)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(UIColor.secondarySystemBackground).opacity(0.6))
                        .padding(.horizontal)
                )
                .padding(.top, 20) // Reduced top padding, since we will control it in BrowserView
                .padding(.bottom, 400) // Padding for keyboard area
            }
        }
        .ignoresSafeArea(.keyboard)
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
