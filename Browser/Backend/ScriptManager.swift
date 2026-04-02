import Foundation
import WebKit

class ScriptManager {
    static let shared = ScriptManager()
    private var scripts: [String: String] = [:] // domain: script

    func registerScript(for domain: String, script: String) {
        scripts[domain] = script
    }

    func injectScripts(into webView: WKWebView, for url: URL?) {
        guard let host = url?.host else { return }

        for (domain, script) in scripts {
            if host.contains(domain) {
                let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                webView.configuration.userContentController.addUserScript(userScript)
            }
        }
    }
}
