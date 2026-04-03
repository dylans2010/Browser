import SwiftUI

struct NewTabView: View {
    @EnvironmentObject var browserViewModel: BrowserViewModel
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var historyManager: HistoryManager

    @StateObject private var suggestionManager = SearchSuggestionManager()
    @FocusState private var isAddressBarFocused: Bool

    var body: some View {
        ZStack {
            VStack {
                // Top: AddressBarView
                AddressBarView(viewModel: browserViewModel, isFocused: $isAddressBarFocused) {
                    loadURL()
                }
                .padding(.top, 40)

                Spacer()

                // Body: Favorites grid
                favoritesGrid

                // Optional: Recent searches
                recentSearches

                Spacer()
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
            )

            // Tapping AddressBar → presents SearchSuggestionsView
            if isAddressBarFocused && !suggestionManager.suggestions.isEmpty {
                VStack {
                    Spacer().frame(height: 100)
                    SearchSuggestionsView(suggestionManager: suggestionManager) { selected in
                        browserViewModel.urlString = selected
                        loadURL()
                        isAddressBarFocused = false
                    }
                    Spacer()
                }
                .zIndex(10)
            }
        }
        .onChange(of: browserViewModel.urlString) { newValue in
            if isAddressBarFocused {
                Task {
                    await suggestionManager.updateSuggestions(for: newValue, history: historyManager.history, favorites: favoritesManager.favorites, learningModel: SearchLearningModel.shared)
                }
            }
        }
    }

    private var favoritesGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                ForEach(favoritesManager.favorites) { favorite in
                    Button(action: {
                        if let url = URL(string: favorite.url) {
                            browserViewModel.addTab(url: url)
                        }
                    }) {
                        VStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 80, height: 80)

                                Text(favorite.title.prefix(1).uppercased())
                                    .font(.title)
                                    .bold()
                            }

                            Text(favorite.title)
                                .font(.caption)
                                .lineLimit(1)
                                .frame(width: 100)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .frame(maxHeight: 300)
    }

    private var recentSearches: some View {
        VStack(alignment: .leading) {
            Text("Recent Searches")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(SearchLearningModel.shared.searchFrequencies.keys.sorted(), id: \.self) { search in
                        Button(action: {
                            browserViewModel.urlString = search
                            loadURL()
                        }) {
                            Text(search)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.thinMaterial)
                                .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func loadURL() {
        var input = browserViewModel.urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if input.contains(".") && !input.contains(" ") {
            if !input.contains("://") { input = "https://\(input)" }
        } else {
            let query = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
            input = "https://www.google.com/search?q=\(query)"
            SearchLearningModel.shared.trackSearch(query: input) // This should be the original query
        }
        browserViewModel.urlString = input
        isAddressBarFocused = false
        browserViewModel.loadURLString()
    }
}
