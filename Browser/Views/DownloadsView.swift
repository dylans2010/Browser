import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header

            if downloadManager.downloads.isEmpty {
                emptyState
            } else {
                downloadsList
            }
        }
        .background(Color(.systemBackground))
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Downloads")
                .font(.title2.weight(.semibold))

            Spacer()

            Button("Clear All") {
                downloadManager.clearAll()
            }
            .disabled(downloadManager.downloads.isEmpty)

            Button("Done") {
                dismiss()
            }
            .fontWeight(.semibold)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 36))
                .foregroundColor(.secondary)

            Text("No downloads yet")
                .font(.headline)

            Text("Files you download will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var downloadsList: some View {
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
        .listStyle(.plain)
    }

    private func statusColor(_ status: DownloadStatus) -> Color {
        switch status {
        case .downloading:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}
