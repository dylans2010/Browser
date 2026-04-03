import SwiftUI

@available(iOS 16.0, *)
struct DeveloperToolsView: View {
    let domInfo: InspectElementTool.DOMInfo?
    let pageURL: String?

    @EnvironmentObject var browserViewModel: BrowserViewModel
    @ObservedObject var networkInspector = NetworkInspector.shared

    var body: some View {
        NavigationView {
            List {
                Section("Page") {
                    row(label: "URL", value: pageURL ?? "—")
                    row(label: "Title", value: (domInfo?.title).flatMap { $0.isEmpty ? nil : $0 } ?? "—")
                    row(label: "Charset", value: (domInfo?.charset).flatMap { $0.isEmpty ? nil : $0 } ?? "—")
                    row(label: "Elements", value: "\(domInfo?.tagCount ?? 0)")
                    row(label: "Scripts", value: "\(domInfo?.scriptCount ?? 0)")
                    row(label: "Links", value: "\(domInfo?.linkCount ?? 0)")
                    row(label: "Images", value: "\(domInfo?.imageCount ?? 0)")
                    row(label: "Iframes", value: "\(domInfo?.iframeCount ?? 0)")
                }

                Section("Console") {
                    if browserViewModel.consoleLogs.isEmpty {
                        Text("No console output yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(browserViewModel.consoleLogs.enumerated()), id: \.offset) { _, log in
                            Text(log)
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }

                Section("Network") {
                    if networkInspector.logs.isEmpty {
                        Text("No captured network logs")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(networkInspector.logs) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(log.method) • \(log.status)")
                                    .font(.caption.weight(.semibold))
                                Text(log.url)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Developer Tools")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Clear Console") {
                        browserViewModel.clearConsoleLogs()
                    }
                    Button("Clear Network") {
                        networkInspector.clear()
                    }
                }
            }
        }
    }

    private func row(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
