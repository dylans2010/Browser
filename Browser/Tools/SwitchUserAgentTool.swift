import Foundation
import WebKit

struct SwitchUserAgentTool {
    static let mobileAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    static let desktopAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    static func toggle(webView: WKWebView) {
        let currentAgent = webView.customUserAgent ?? ""
        if currentAgent == desktopAgent {
            webView.customUserAgent = nil // reset to default mobile
        } else {
            webView.customUserAgent = desktopAgent
        }
        webView.reload()
    }

    static func isDesktop(webView: WKWebView) -> Bool {
        return webView.customUserAgent == desktopAgent
    }
}
