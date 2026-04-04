import SwiftUI

@available(iOS 16.0, *)
struct NewTabView: View {
    @EnvironmentObject var browserViewModel: BrowserViewModel
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var historyManager: HistoryManager

    @AppStorage("homePageBackgroundStyle") var backgroundStyle: String = "Blurred Camera"

    var onSearch: () -> Void = {}

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    headerSection

                    HStack(spacing: 15) {
                        weatherWidget
                        newsWidget
                    }
                    .padding(.horizontal)

                    favoritesSection

                    recentSearchesSection

                    Spacer().frame(height: 50)
                }
                .padding(.top, 60)
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
            Text(greeting)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .padding(.top, 20)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 18 { return "Good Afternoon" }
        return "Good Evening"
    }


    private var weatherWidget: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow)
                Text("72°")
                    .font(.title2.bold())
            }
            Text("Sunny")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("San Francisco")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .cornerRadius(20)
    }

    private var newsWidget: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Top News")
                .font(.caption.bold())
                .foregroundColor(.blue)
            Text("New breakthrough in energy...")
                .font(.system(size: 14, weight: .medium))
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .cornerRadius(20)
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
                            onSearch()
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

}
