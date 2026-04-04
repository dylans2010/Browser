import SwiftUI
import WebKit

struct PageInfoTool {
    static func execute(webView: WKWebView, completion: @escaping (PageInfo) -> Void) {
        let title = webView.title ?? "Unknown Title"
        let url = webView.url?.absoluteString ?? "No URL"
        let isSecure = webView.url?.scheme == "https"

        // Basic cookie count estimation
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            let info = PageInfo(title: title, url: url, isSecure: isSecure, cookieCount: cookies.count)
            completion(info)
        }
    }
}

struct PageInfo: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let isSecure: Bool
    let cookieCount: Int
}
