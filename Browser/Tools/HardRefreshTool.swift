import Foundation
import WebKit

struct HardRefreshTool {
    static func execute(in webView: WKWebView) {
        webView.reloadFromOrigin()
    }
}
