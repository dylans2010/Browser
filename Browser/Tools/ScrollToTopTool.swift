import Foundation
import WebKit

struct ScrollToTopTool {
    static func execute(in webView: WKWebView) {
        webView.evaluateJavaScript("window.scrollTo({ top: 0, behavior: 'smooth' })")
    }
}
