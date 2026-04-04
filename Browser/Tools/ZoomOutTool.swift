import WebKit

struct ZoomOutTool {
    static func execute(webView: WKWebView) {
        if webView.pageZoom > 0.1 {
            webView.pageZoom -= 0.1
        }
    }
}
