import WebKit

struct ResetTextSizeTool {
    static func execute(webView: WKWebView) {
        let script = "document.body.style.zoom = 1.0;"
        webView.evaluateJavaScript(script)
    }
}
