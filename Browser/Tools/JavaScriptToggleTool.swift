import Foundation
import WebKit

struct JavaScriptToggleTool {
    static func execute(in webView: WKWebView, isEnabled: Bool) {
        webView.configuration.preferences.javaScriptEnabled = isEnabled
        webView.reload()
    }
}
