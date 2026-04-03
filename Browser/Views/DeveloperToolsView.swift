import SwiftUI

@available(iOS 16.0, *)
struct DeveloperToolsView: View {
    let domInfo: InspectElementTool.DOMInfo

    @EnvironmentObject var browserViewModel: BrowserViewModel
    @ObservedObject var networkInspector = NetworkInspector.shared

    var body: some View {
        NavigationView {
            List {
                Section("Page") {
                    row(label: "Title", value: domInfo.title.isEmpty ? "—" : domInfo.title)
                    row(label: "Charset", value: domInfo.charset.isEmpty ? "—" : domInfo.charset)
                    row(label: "Elements", value: "\(domInfo.tagCount)")
                    row(label: "Scripts", value: "\(domInfo.scriptCount)")
                    row(label: "Links", value: "\(domInfo.linkCount)")
                    row(label: "Images", value: "\(domInfo.imageCount)")
                    row(label: "Iframes", value: "\(domInfo.iframeCount)")
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
