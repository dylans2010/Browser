import SwiftUI

struct CollectionsDetailView: View {
    let collection: Collection
    @EnvironmentObject var browserViewModel: BrowserViewModel
    @EnvironmentObject var collectionsManager: CollectionsManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            Section {
                Button("Open All (\(collection.urls.count))") {
                    for urlString in collection.urls {
                        if let url = URL(string: urlString) {
                            browserViewModel.addTab(url: url)
                        }
                    }
                    dismiss()
                }
                .foregroundColor(.blue)
            }

            Section("Tabs") {
                ForEach(collection.urls, id: \.self) { urlString in
                    Button(action: {
                        if let url = URL(string: urlString) {
                            browserViewModel.addTab(url: url)
                        }
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "link")
                            Text(urlString)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                Button("Delete Collection", role: .destructive) {
                    collectionsManager.deleteCollection(id: collection.id)
                    dismiss()
                }
            }
        }
        .navigationTitle(collection.name)
    }
}
