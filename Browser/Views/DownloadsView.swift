import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(downloadManager.downloads) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.fileName)
                                .font(.headline)
                                .lineLimit(1)

                            ProgressView(value: item.progress)
                                .progressViewStyle(.linear)
                                .tint(statusColor(item.status))

                            HStack {
                                Text(item.status.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(statusColor(item.status))

                                if let url = item.downloadURL {
                                    Text(url.absoluteString)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }

                        Spacer()

                        if item.status == .completed {
                            HStack(spacing: 12) {
                                Button(action: {
                                    downloadManager.openFile(item: item)
                                }) {
                                    Image(systemName: "doc")
                                }
                                .buttonStyle(.plain)

                                if let url = item.localURL {
                                    ShareLink(item: url) {
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                }
                            }
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
            .toolbar(content: {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Clear All") {
                        downloadManager.clearAll()
                    }
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            })
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
