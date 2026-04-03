import Foundation
import WebKit

struct SavePageOfflineTool {
    /// Saves the current page HTML to a local file.
    static func execute(webView: WKWebView, completion: @escaping (URL?) -> Void) {
        webView.evaluateJavaScript("document.documentElement.outerHTML") { result, _ in
            guard let html = result as? String else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let host = webView.url?.host ?? "page"
            let fileName = "\(host)_\(Int(Date().timeIntervalSince1970)).html"
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            do {
                try html.write(to: tmpURL, atomically: true, encoding: .utf8)
                DispatchQueue.main.async { completion(tmpURL) }
            } catch {
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
}
