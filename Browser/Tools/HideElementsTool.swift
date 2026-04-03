import Foundation
import WebKit

struct HideElementsTool {
    static func execute(webView: WKWebView, elementHiderManager: ElementHiderManager) {
        let script = elementHiderManager.getSelectionScript()
        webView.evaluateJavaScript(script)
    }
}
