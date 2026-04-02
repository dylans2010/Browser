import Foundation
import WebKit

struct ForwardTool {
    static func execute(in webView: WKWebView) {
        if webView.canGoForward {
            webView.goForward()
        }
    }
}
