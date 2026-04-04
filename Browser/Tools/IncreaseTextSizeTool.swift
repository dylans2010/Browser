import WebKit

struct IncreaseTextSizeTool {
    static func execute(webView: WKWebView) {
        let script = "document.body.style.zoom = (parseFloat(document.body.style.zoom) || 1) + 0.1;"
        webView.evaluateJavaScript(script)
    }
}
