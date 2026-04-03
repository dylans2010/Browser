import SwiftUI

@available(iOS 16.0, *)
struct CollectionsView: View {
    @EnvironmentObject var collectionsManager: CollectionsManager
    @EnvironmentObject var browserViewModel: BrowserViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showCreate = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                    ForEach(collectionsManager.collections) { collection in
                        NavigationLink(destination: CollectionsDetailView(collection: collection)) {
                            VStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(hex: collection.color).opacity(0.2))
                                        .frame(height: 120)

                                    Image(systemName: collection.sfSymbol)
                                        .font(.largeTitle)
                                        .foregroundColor(Color(hex: collection.color))
                                }

                                Text(collection.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("\(collection.urls.count) Tabs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showCreate = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreate) {
                CollectionsCreateView()
                    .environmentObject(browserViewModel)
            }
        }
    }
}
