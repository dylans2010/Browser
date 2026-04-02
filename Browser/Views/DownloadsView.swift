import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(downloadManager.downloads) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.fileName)
                                .font(.headline)
                                .lineLimit(1)

                            ProgressView(value: item.progress)
                                .progressViewStyle(.linear)

                            Text(item.status.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(statusColor(item.status))
                        }

                        Spacer()

                        if item.status == .completed {
                            Button(action: {
                                downloadManager.openFile(item: item)
                            }) {
                                Image(systemName: "doc")
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: {
                            downloadManager.deleteFile(item: item)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Downloads")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear All") {
                        downloadManager.clearAll()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func statusColor(_ status: DownloadStatus) -> Color {
        switch status {
        case .downloading: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}
