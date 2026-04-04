import WebKit

struct ResetZoomTool {
    static func execute(webView: WKWebView) {
        webView.pageZoom = 1.0
    }
}
