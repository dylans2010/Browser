import SwiftUI

struct NetworkLogsView: View {
    @ObservedObject var networkInspector = NetworkInspector.shared

    var body: some View {
        NavigationView {
            Group {
                if networkInspector.logs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "network.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No network requests yet")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(networkInspector.logs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.method)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.blue.opacity(0.2)))
                                if log.status > 0 {
                                    Text("\(log.status)")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(statusColor(log.status).opacity(0.2)))
                                        .foregroundColor(statusColor(log.status))
                                }
                                Spacer()
                            }
                            Text(log.url)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Network Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        networkInspector.clear()
                    }
                }
            }
        }
    }

    private func statusColor(_ status: Int) -> Color {
        switch status {
        case 200..<300: return .green
        case 300..<400: return .orange
        case 400..<600: return .red
        default: return .secondary
        }
    }
}
