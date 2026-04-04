import WebKit

struct DecreaseTextSizeTool {
    static func execute(webView: WKWebView) {
        let script = "document.body.style.zoom = Math.max(0.1, (parseFloat(document.body.style.zoom) || 1) - 0.1);"
        webView.evaluateJavaScript(script)
    }
}
