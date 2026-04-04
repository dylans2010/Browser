import WebKit

struct ZoomInTool {
    static func execute(webView: WKWebView) {
        webView.pageZoom += 0.1
    }
}
