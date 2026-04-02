import Foundation
import WebKit

struct ReloadTool {
    static func execute(in webView: WKWebView) {
        webView.reload()
    }
}
