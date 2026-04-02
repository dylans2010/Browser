import Foundation
import WebKit

struct FindOnPageTool {
    static func execute(in webView: WKWebView, query: String) {
        guard !query.isEmpty else { return }
        // Highlight logic using JavaScript
        let js = """
        (function() {
            var searchStr = "\(query)";
            var bodyText = document.body.innerHTML;
            var regExp = new RegExp(searchStr, "gi");
            document.body.innerHTML = bodyText.replace(regExp, function(match) {
                return "<mark style='background-color: yellow;'>" + match + "</mark>";
            });
        })();
        """
        webView.evaluateJavaScript(js)
    }

    static func clear(in webView: WKWebView) {
        let js = "document.querySelectorAll('mark').forEach(e => e.outerHTML = e.innerText);"
        webView.evaluateJavaScript(js)
    }
}
