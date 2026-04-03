import Foundation
import WebKit

@available(iOS 16.0, *)
class BrowserViewModel: NSObject, ObservableObject {
    @Published var tabs: [TabItem] = []
    @Published var activeTabId: UUID?
    @Published var urlString: String = ""
    @Published var canGoBack = false
    @Published var canGoForward = false
    var historyManager: HistoryManager?
    var downloadManager: DownloadManager?

    var activeTab: TabItem? {
        tabs.first(where: { $0.id == activeTabId })
    }

    override init() {
        super.init()
        loadPersistedTabs()
    }

    private func saveTabs() {
        let urls = tabs.compactMap { $0.url?.absoluteString }
        UserDefaults.standard.set(urls, forKey: "persisted_tab_urls")
    }

    func suspendInactiveTabs() {
        for index in tabs.indices {
            if tabs[index].id != activeTabId {
                tabs[index].webView.loadHTMLString("", baseURL: nil)
            }
        }
    }

    private func loadPersistedTabs() {
        if let urls = UserDefaults.standard.stringArray(forKey: "persisted_tab_urls"), !urls.isEmpty {
            for urlString in urls {
                addTab(url: URL(string: urlString))
            }
        } else {
            let defaultURL = UserDefaults.standard.string(forKey: "Default-URL") ?? ""
            addTab(url: URL(string: defaultURL))
        }
    }

    func addTab(url: URL? = nil, isEphemeral: Bool = false) {
        let newTab = TabItem(url: url, isEphemeral: isEphemeral)
        newTab.webView.navigationDelegate = self
        ScriptManager.shared.injectScripts(into: newTab.webView, for: url)
        tabs.append(newTab)
        activeTabId = newTab.id
        if let url = url {
            newTab.webView.load(URLRequest(url: url))
        }
    }

    func removeTab(id: UUID) {
        if let tab = tabs.first(where: { $0.id == id }) {
            if tab.isEphemeral {
                let saveDataWhilePrivate = UserDefaults.standard.bool(forKey: "saveDataWhilePrivate")
                if saveDataWhilePrivate {
                    tab.webView.configuration.websiteDataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) {}
                }
            }
        }

        tabs.removeAll(where: { $0.id == id })
        if activeTabId == id {
            activeTabId = tabs.last?.id
        }
        saveTabs()
    }

    func loadURLString() {
        guard let activeTab = activeTab, let url = URL(string: urlString) else { return }
        activeTab.webView.load(URLRequest(url: url))
    }

    func goBack() {
        activeTab?.webView.goBack()
    }

    func goForward() {
        activeTab?.webView.goForward()
    }

    func reload() {
        activeTab?.webView.reload()
    }

    func extractPageContent() async -> String {
        guard let webView = activeTab?.webView else { return "" }

        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                webView.evaluateJavaScript("document.body.innerText") { (result, error) in
                    if let content = result as? String {
                        continuation.resume(returning: content)
                    } else {
                        continuation.resume(returning: "")
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, *)
extension BrowserViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if TrackerBlocker.shared.shouldBlock(request: navigationAction.request) {
            decisionHandler(.cancel)
            return
        }

        if let url = navigationAction.request.url {
            if AdBlocker.shared.shouldBlock(url: url) {
                decisionHandler(.cancel)
                return
            }
        }

        if let url = navigationAction.request.url {
            NetworkInspector.shared.logRequest(url: url.absoluteString, method: navigationAction.request.httpMethod ?? "GET", status: 0)

            // Check for potential downloads (file extensions or specific headers)
            let pathExtension = url.pathExtension.lowercased()
            let downloadExtensions = ["zip", "pdf", "dmg", "pkg", "exe", "ipa", "apk", "mp3", "mp4", "mov", "wav"]
            if downloadExtensions.contains(pathExtension) {
                downloadManager?.startDownload(url: url)
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let response = navigationResponse.response as? HTTPURLResponse {
            let contentType = response.allHeaderFields["Content-Type"] as? String ?? ""
            let contentDisposition = response.allHeaderFields["Content-Disposition"] as? String ?? ""

            if contentDisposition.contains("attachment") || contentType.contains("application/octet-stream") {
                if let url = response.url {
                    downloadManager?.startDownload(url: url)
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let index = tabs.firstIndex(where: { $0.webView == webView }) {
            tabs[index].url = webView.url
            tabs[index].title = webView.title ?? "Untitled"

            if activeTabId == tabs[index].id {
                urlString = webView.url?.absoluteString ?? ""
                canGoBack = webView.canGoBack
                canGoForward = webView.canGoForward
            }

            if let url = webView.url?.absoluteString {
                if tabs[index].isEphemeral {
                    let saveDataWhilePrivate = UserDefaults.standard.bool(forKey: "saveDataWhilePrivate")
                    if !saveDataWhilePrivate {
                        historyManager?.addHistory(url: url, title: webView.title ?? "Untitled")
                    }
                } else {
                    historyManager?.addHistory(url: url, title: webView.title ?? "Untitled")
                }
            }

            saveTabs()
        }
    }
}
