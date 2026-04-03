import SwiftUI
import WebKit

@available(iOS 16.0, *)
struct DeveloperToolsView: View {
    let webView: WKWebView

    @EnvironmentObject var browserViewModel: BrowserViewModel
    @ObservedObject var networkInspector = NetworkInspector.shared
    @State private var domInfo = InspectElementTool.DOMInfo(tagCount: 0, scriptCount: 0, linkCount: 0, imageCount: 0, iframeCount: 0, title: "", charset: "")
    @State private var hasLoadedDOMInfo = false
    @State private var cookies: [String] = []
    @State private var localStorage: [String: String] = [:]
    @State private var performanceMetrics: [String: String] = [:]

    var body: some View {
        NavigationView {
            List {
                Section("Page") {
                    if hasLoadedDOMInfo {
                        row(label: "Title", value: domInfo.title.isEmpty ? "—" : domInfo.title)
                        row(label: "Charset", value: domInfo.charset.isEmpty ? "—" : domInfo.charset)
                        row(label: "Elements", value: "\(domInfo.tagCount)")
                        row(label: "Scripts", value: "\(domInfo.scriptCount)")
                        row(label: "Links", value: "\(domInfo.linkCount)")
                        row(label: "Images", value: "\(domInfo.imageCount)")
                        row(label: "Iframes", value: "\(domInfo.iframeCount)")
                    } else {
                        HStack {
                            ProgressView()
                            Text("Loading page diagnostics…")
                                .foregroundColor(.secondary)
                        }
                    }
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

                Section("Cookies") {
                    if cookies.isEmpty {
                        Text("No cookies found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(cookies, id: \.self) { cookie in
                            Text(cookie)
                                .font(.caption.monospaced())
                        }
                    }
                }

                Section("Local Storage") {
                    if localStorage.isEmpty {
                        Text("No local storage items")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(localStorage.keys.sorted()), id: \.self) { key in
                            VStack(alignment: .leading) {
                                Text(key).font(.caption.bold())
                                Text(localStorage[key] ?? "").font(.caption2.monospaced()).foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section("Performance") {
                    if performanceMetrics.isEmpty {
                        Text("No performance data")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(performanceMetrics.keys.sorted()), id: \.self) { key in
                            row(label: key, value: performanceMetrics[key] ?? "")
                        }
                    }
                }
            }
            .navigationTitle("Developer Tools")
            .onAppear {
                refreshDOMInfo()
                fetchDiagnostics()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        refreshDOMInfo()
                    }
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

    private func refreshDOMInfo() {
        hasLoadedDOMInfo = false
        InspectElementTool.inspect(webView: webView) { info in
            domInfo = info
            hasLoadedDOMInfo = true
        }
    }

    private func fetchDiagnostics() {
        // Fetch Cookies
        webView.evaluateJavaScript("document.cookie") { result, _ in
            if let cookieStr = result as? String, !cookieStr.isEmpty {
                self.cookies = cookieStr.components(separatedBy: "; ")
            }
        }

        // Fetch Local Storage
        let lsJS = "JSON.stringify(localStorage)"
        webView.evaluateJavaScript(lsJS) { result, _ in
            if let jsonStr = result as? String,
               let data = jsonStr.data(using: .utf8),
               let dict = try? JSONDecoder().decode([String: String].self, from: data) {
                self.localStorage = dict
            }
        }

        // Fetch Performance Metrics
        let perfJS = """
        (function() {
            const t = performance.timing;
            return JSON.stringify({
                "Page Load": (t.loadEventEnd - t.navigationStart) + "ms",
                "DOM Ready": (t.domContentLoadedEventEnd - t.navigationStart) + "ms",
                "DNS Lookup": (t.domainLookupEnd - t.domainLookupStart) + "ms",
                "TCP Connect": (t.connectEnd - t.connectStart) + "ms",
                "Response Time": (t.responseEnd - t.requestStart) + "ms"
            });
        })()
        """
        webView.evaluateJavaScript(perfJS) { result, _ in
            if let jsonStr = result as? String,
               let data = jsonStr.data(using: .utf8),
               let dict = try? JSONDecoder().decode([String: String].self, from: data) {
                self.performanceMetrics = dict
            }
        }
    }
}
