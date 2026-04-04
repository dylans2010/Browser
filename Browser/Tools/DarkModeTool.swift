import Foundation
import WebKit

struct DarkModeTool {
    private static let darkModeCSS = """
    html { filter: invert(90%) hue-rotate(180deg) !important; }
    img, video, canvas { filter: invert(100%) hue-rotate(180deg) !important; }
    """

    static func enable(in webView: WKWebView) {
        let js = """
        (function() {
            var existing = document.getElementById('__browserDarkMode');
            if (!existing) {
                var style = document.createElement('style');
                style.id = '__browserDarkMode';
                style.innerHTML = `\(darkModeCSS)`;
                document.head.appendChild(style);
            }
        })();
        """
        webView.evaluateJavaScript(js)
    }

    static func disable(in webView: WKWebView) {
        let js = """
        (function() {
            var el = document.getElementById('__browserDarkMode');
            if (el) el.remove();
        })();
        """
        webView.evaluateJavaScript(js)
    }

    static func execute(webView: WKWebView) {
        toggle(in: webView) { _ in }
    }

    static func toggle(in webView: WKWebView, completion: @escaping (Bool) -> Void) {
        let js = "!!document.getElementById('__browserDarkMode')"
        webView.evaluateJavaScript(js) { result, _ in
            let isEnabled = result as? Bool ?? false
            if isEnabled {
                disable(in: webView)
                completion(false)
            } else {
                enable(in: webView)
                completion(true)
            }
        }
    }
}
