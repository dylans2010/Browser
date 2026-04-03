import Foundation
import WebKit

struct RevertToOriginalTool {
    static func execute(url: URL?, elementHiderManager: ElementHiderManager, webView: WKWebView) {
        guard let domain = url?.host else { return }
        elementHiderManager.clearSelectors(for: domain)
        webView.reload()
    }
}
