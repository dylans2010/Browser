import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var historyManager: HistoryManager

    @EnvironmentObject var browserViewModel: BrowserViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(historyManager.history) { item in
                    Button(action: {
                        if let url = URL(string: item.url) {
                            browserViewModel.addTab(url: url)
                            dismiss()
                        }
                    }) {
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.headline)
                                .lineLimit(1)
                            Text(item.url)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Text(item.date, style: .time)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        historyManager.history.remove(at: index)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            })
        }
    }
}
