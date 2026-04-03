import SwiftUI

@available(iOS 16.0, *)
struct SaveForLaterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var browserViewModel: BrowserViewModel
    @EnvironmentObject var saveForLaterManager: SaveForLaterManager

    var body: some View {
        NavigationView {
            List {
                ForEach(saveForLaterManager.items) { item in
                    Button {
                        if let url = URL(string: item.url) {
                            browserViewModel.addTab(url: url)
                            dismiss()
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.url)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Text(item.savedAt, style: .date)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    offsets.forEach { index in
                        saveForLaterManager.remove(id: saveForLaterManager.items[index].id)
                    }
                }
            }
            .navigationTitle("Save For Later")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") { saveForLaterManager.clear() }
                        .disabled(saveForLaterManager.items.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
