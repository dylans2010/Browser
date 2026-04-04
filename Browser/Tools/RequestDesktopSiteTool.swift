import WebKit

struct RequestDesktopSiteTool {
    static func execute(webView: WKWebView) {
        let desktopUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

        if webView.customUserAgent == desktopUA {
            webView.customUserAgent = nil
        } else {
            webView.customUserAgent = desktopUA
        }

        webView.reload()
    }
}
