import Foundation
import WebKit

struct ViewPageSourceTool {
    /// Extracts raw HTML source from the current page.
    static func execute(webView: WKWebView, completion: @escaping (String) -> Void) {
        webView.evaluateJavaScript("document.documentElement.outerHTML") { result, _ in
            let html = result as? String ?? ""
            DispatchQueue.main.async { completion(html) }
        }
    }
}
