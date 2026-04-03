import Foundation
import WebKit

struct StopLoadingTool {
    static func execute(in webView: WKWebView) {
        webView.stopLoading()
    }
}
