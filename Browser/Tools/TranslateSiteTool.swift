import Foundation
import WebKit

struct TranslateSiteTool {
    static func execute(in webView: WKWebView, targetLanguage: String) {
        guard let currentURL = webView.url else { return }

        // Use Google Translate's mobile web proxy for better reliability
        let encodedURL = currentURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let translateURLString = "https://translate.google.com/translate?sl=auto&tl=\(targetLanguage)&u=\(encodedURL)"

        if let url = URL(string: translateURLString) {
            webView.load(URLRequest(url: url))
        }
    }
}
