import Foundation
import WebKit

struct ScrollToBottomTool {
    static func execute(in webView: WKWebView) {
        webView.evaluateJavaScript(
            "window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' })"
        )
    }
}
