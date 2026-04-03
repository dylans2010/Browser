import Foundation
import WebKit
import Combine

@available(iOS 16.0, *)
class BrowserViewModel: NSObject, ObservableObject {
    @Published var tabs: [TabItem] = []
    @Published var activeTabId: UUID?
    @Published var urlString: String = ""
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var loadError: String? = nil
    @Published var isHideElementsModeEnabled = false
    @Published var consoleLogs: [String] = []

    var historyManager: HistoryManager?
    var downloadManager: DownloadManager?
    var adBlocker = AdBlocker.shared
    var networkInspector = NetworkInspector.shared
    var elementHiderManager: ElementHiderManager?
    var websiteStyleManager: WebsiteStyleManager?

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
            if !defaultURL.isEmpty {
                addTab(url: URL(string: defaultURL))
            }
        }
    }

    func addTab(url: URL? = nil, isEphemeral: Bool = false) {
        let newTab = TabItem(url: url, isEphemeral: isEphemeral)
        newTab.webView.navigationDelegate = self
        newTab.webView.configuration.userContentController.add(self, name: "elementHider")
        newTab.webView.configuration.userContentController.add(self, name: "devConsole")

        injectScripts(into: newTab.webView, for: url)

        tabs.append(newTab)
        activeTabId = newTab.id
        if let url = url {
            newTab.webView.load(URLRequest(url: url))
        }
    }

    func removeTab(id: UUID) {
        if let tab = tabs.first(where: { $0.id == id }) {
            tab.webView.navigationDelegate = nil
            tab.webView.configuration.userContentController.removeScriptMessageHandler(forName: "elementHider")
            tab.webView.configuration.userContentController.removeScriptMessageHandler(forName: "devConsole")
            tab.webView.stopLoading()

            if tab.isEphemeral {
                tab.webView.configuration.websiteDataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) {}
            }
        }

        tabs.removeAll(where: { $0.id == id })
        if activeTabId == id {
            activeTabId = tabs.last?.id
        }

        if tabs.isEmpty {
            activeTabId = nil
            urlString = ""
        }

        saveTabs()
    }

    func loadURLString() {
        guard let activeTab = activeTab, let url = URL(string: urlString) else { return }
        loadError = nil
        activeTab.webView.load(URLRequest(url: url))
    }

    func activateTab(id: UUID) {
        guard let tab = tabs.first(where: { $0.id == id }) else { return }
        activeTabId = id
        urlString = tab.url?.absoluteString ?? ""
        canGoBack = tab.webView.canGoBack
        canGoForward = tab.webView.canGoForward
        loadError = nil
    }

    func goBack() {
        activeTab?.webView.goBack()
    }

    func goForward() {
        activeTab?.webView.goForward()
    }

    func reload() {
        loadError = nil
        activeTab?.webView.reload()
    }

    func hardRefresh() {
        loadError = nil
        activeTab?.webView.reloadFromOrigin()
    }

    func stopLoading() {
        activeTab?.webView.stopLoading()
        isLoading = false
    }

    func closeOtherTabs() {
        guard let activeId = activeTabId else { return }
        let otherTabs = tabs.filter { $0.id != activeId }
        for tab in otherTabs {
            removeTab(id: tab.id)
        }
    }

    func duplicateTab() {
        guard let activeTab = activeTab else { return }
        addTab(url: activeTab.url)
    }

    func injectScripts(into webView: WKWebView, for url: URL?) {
        let contentController = webView.configuration.userContentController
        contentController.removeAllUserScripts()

        // Ad Blocker
        let adScript = WKUserScript(source: adBlocker.getBlockingScript(), injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(adScript)

        if let domain = url?.host {
            // Element Hider
            if let hiderManager = elementHiderManager {
                let hiderScript = hiderManager.getInjectionScript(for: domain)
                if !hiderScript.isEmpty {
                    let script = WKUserScript(source: hiderScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                    contentController.addUserScript(script)
                }
            }

            // Website Style
            if let styleManager = websiteStyleManager {
                let styleScript = styleManager.getInjectionScript(for: domain)
                if !styleScript.isEmpty {
                    let script = WKUserScript(source: styleScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                    contentController.addUserScript(script)
                }
            }
        }

        // Also inject existing scripts
        ScriptManager.shared.injectScripts(into: webView, for: url)

        let consoleHookScript = """
        (function() {
            if (window.__devConsoleHooked) return;
            window.__devConsoleHooked = true;
            const methods = ['log', 'info', 'warn', 'error', 'debug'];
            methods.forEach(function(level) {
                const original = console[level];
                console[level] = function() {
                    const message = Array.from(arguments).map(function(arg) {
                        try {
                            return typeof arg === 'string' ? arg : JSON.stringify(arg);
                        } catch (_) {
                            return String(arg);
                        }
                    }).join(' ');
                    window.webkit.messageHandlers.devConsole.postMessage(level.toUpperCase() + ': ' + message);
                    original.apply(console, arguments);
                };
            });
        })();
        """
        contentController.addUserScript(WKUserScript(source: consoleHookScript, injectionTime: .atDocumentStart, forMainFrameOnly: false))
    }

    func enableHideElementsMode(using manager: ElementHiderManager) {
        guard let webView = activeTab?.webView else { return }
        isHideElementsModeEnabled = true
        webView.evaluateJavaScript(manager.getSelectionScript())
    }

    func disableHideElementsMode() {
        isHideElementsModeEnabled = false
        activeTab?.webView.evaluateJavaScript("if (window.__elementHiderCleanup) { window.__elementHiderCleanup(); }")
    }

    func clearConsoleLogs() {
        consoleLogs.removeAll()
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
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if activeTab?.webView == webView {
            isLoading = true
            loadError = nil
            canGoBack = webView.canGoBack
            canGoForward = webView.canGoForward
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let index = tabs.firstIndex(where: { $0.webView == webView }) {
            let tabId = tabs[index].id
            tabs[index].url = webView.url
            tabs[index].title = webView.title ?? "Untitled"

            // Re-inject scripts on navigation
            injectScripts(into: webView, for: webView.url)

            if activeTabId == tabs[index].id {
                urlString = webView.url?.absoluteString ?? ""
                canGoBack = webView.canGoBack
                canGoForward = webView.canGoForward
                isLoading = false
                loadError = nil
            }

            if let url = webView.url?.absoluteString {
                historyManager?.addHistory(url: url, title: webView.title ?? "Untitled")
            }

            saveTabs()
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if isHideElementsModeEnabled {
            decisionHandler(.cancel)
            return
        }

        if let url = navigationAction.request.url {
            networkInspector.logRequest(url: url.absoluteString, method: navigationAction.request.httpMethod ?? "GET", status: 0)
            if adBlocker.shouldBlock(url: url) {
                decisionHandler(.cancel)
                return
            }

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
}

@available(iOS 16.0, *)
extension BrowserViewModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "elementHider", let selector = message.body as? String {
            if let domain = activeTab?.url?.host {
                elementHiderManager?.hideElement(selector: selector, for: domain)
                reload() // Reload to apply
            }
        } else if message.name == "devConsole", let log = message.body as? String {
            DispatchQueue.main.async {
                self.consoleLogs.append(log)
                if self.consoleLogs.count > 500 {
                    self.consoleLogs.removeFirst(self.consoleLogs.count - 500)
                }
            }
        }
    }
}
