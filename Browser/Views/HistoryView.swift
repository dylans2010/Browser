import SwiftUI

@available(iOS 16.0, *)
struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var historyManager: HistoryManager

    @EnvironmentObject var browserViewModel: BrowserViewModel

    private enum DeleteWindow: String, CaseIterable, Identifiable {
        case twelveHours = "12 hours"
        case oneDay = "1 day"
        case oneWeek = "1 week"
        case oneMonth = "1 month"

        var id: String { rawValue }
        var interval: TimeInterval {
            switch self {
            case .twelveHours: return 60 * 60 * 12
            case .oneDay: return 60 * 60 * 24
            case .oneWeek: return 60 * 60 * 24 * 7
            case .oneMonth: return 60 * 60 * 24 * 30
            }
        }
    }

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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu("Delete:") {
                        ForEach(DeleteWindow.allCases) { window in
                            Button("Last \(window.rawValue)") {
                                historyManager.deleteHistory(inPast: window.interval)
                            }
                        }
                        Divider()
                        Button("All History", role: .destructive) {
                            historyManager.clearHistory()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
