import SwiftUI

@available(iOS 16.0, *)
struct BookmarksView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var browserViewModel: BrowserViewModel
    @EnvironmentObject var favoritesManager: FavoritesManager

    var body: some View {
        NavigationView {
            List {
                ForEach(favoritesManager.favorites) { bookmark in
                    Button {
                        if let url = URL(string: bookmark.url) {
                            browserViewModel.addTab(url: url)
                            dismiss()
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bookmark.title)
                                .font(.headline)
                            Text(bookmark.url)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets {
                        let url = favoritesManager.favorites[index].url
                        favoritesManager.removeFavorite(url: url)
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        favoritesManager.favorites.removeAll()
                    }
                    .disabled(favoritesManager.favorites.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
