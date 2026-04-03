import Foundation
import WebKit

import WebKit

struct FindOnPageTool {
    static func execute(in webView: WKWebView, query: String) {
        guard !query.isEmpty else { return }

        // Use window.find() which is a more modern and safe way to find and highlight text in a web page.
        // It's non-destructive and doesn't break event listeners.
        // Parameters: (string, caseSensitive, backwards, wrapAround, wholeWord, searchInFrames, showDialog)
        let js = "window.find('\(query)', false, false, true, false, true, false);"
        webView.evaluateJavaScript(js)
    }

    static func clear(in webView: WKWebView) {
        // Clearing selection is simpler and safer than innerHTML replacement
        let js = "window.getSelection().removeAllRanges();"
        webView.evaluateJavaScript(js)
    }
}
