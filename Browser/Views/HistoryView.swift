import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var historyManager: HistoryManager

    var body: some View {
        NavigationView {
            List(historyManager.history) { item in
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
            .navigationTitle("History")
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            })
        }
    }
}
