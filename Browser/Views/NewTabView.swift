import SwiftUI

@available(iOS 16.0, *)
struct NewTabView: View {
    @EnvironmentObject var browserViewModel: BrowserViewModel
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var historyManager: HistoryManager

    @StateObject private var suggestionManager = SearchSuggestionManager()
    @FocusState private var isAddressBarFocused: Bool

    @AppStorage("homePageBackgroundStyle") var backgroundStyle: String = "Blurred Camera"

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    // Top Spacer for AddressBar area
                    Spacer().frame(height: 100)

                    headerSection

                    // Body: Favorites grid
                    favoritesSection

                    // Optional: Recent searches
                    recentSearchesSection

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal)
            }

            // AddressBar at top
            VStack {
                AddressBarView(viewModel: browserViewModel, isFocused: $isAddressBarFocused) {
                    loadURL()
                }
                .padding(.top, 20)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color(UIColor.systemBackground).opacity(0.8), Color(UIColor.systemBackground).opacity(0)]), startPoint: .top, endPoint: .bottom)
                        .edgesIgnoringSafeArea(.top)
                )
                Spacer()
            }

            // Tapping AddressBar → presents SearchSuggestionsView
            if isAddressBarFocused && !suggestionManager.suggestions.isEmpty {
                SearchSuggestionsView(suggestionManager: suggestionManager, query: browserViewModel.urlString) { selected in
                    browserViewModel.urlString = selected
                    loadURL()
                    isAddressBarFocused = false
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

    private var backgroundLayer: some View {
        Group {
            if backgroundStyle == "Blurred Camera" {
                Color.blue.opacity(0.1).ignoresSafeArea() // Placeholder for camera
                    .overlay(.ultraThinMaterial)
            } else if backgroundStyle == "Frosted Glass" {
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .overlay(.ultraThinMaterial)
            } else {
                Color(UIColor.systemBackground).ignoresSafeArea()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "safari.fill")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                .shadow(radius: 5)

            Text("Good Morning") // Could be dynamic
                .font(.title.bold())
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Favorites")
                .font(.headline)
                .padding(.horizontal, 5)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                ForEach(favoritesManager.favorites) { favorite in
                    Button(action: {
                        if let url = URL(string: favorite.url) {
                            browserViewModel.addTab(url: url)
                        }
                    }) {
                        VStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.regularMaterial)
                                    .frame(width: 64, height: 64)
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)

                                if let host = URL(string: favorite.url)?.host {
                                    AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?sz=128&domain=\(host)")) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Text(favorite.title.prefix(1).uppercased())
                                            .font(.title2.bold())
                                    }
                                    .frame(width: 32, height: 32)
                                    .cornerRadius(8)
                                } else {
                                    Text(favorite.title.prefix(1).uppercased())
                                        .font(.title2.bold())
                                }
                            }

                            Text(favorite.title)
                                .font(.caption2)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .frame(width: 80)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Add Favorite button
                Button(action: {
                    // Action for adding favorite
                }) {
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.regularMaterial)
                                .frame(width: 64, height: 64)
                                .overlay(Image(systemName: "plus").foregroundColor(.secondary))
                        }
                        Text("Add")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Searches")
                .font(.headline)
                .padding(.horizontal, 5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SearchLearningModel.shared.searchFrequencies.keys.sorted(), id: \.self) { search in
                        Button(action: {
                            browserViewModel.urlString = search
                            loadURL()
                        }) {
                            Text(search)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.regularMaterial)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
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
            SearchLearningModel.shared.trackSearch(query: input)
        }
        browserViewModel.urlString = input
        isAddressBarFocused = false
        browserViewModel.loadURLString()
    }
}
