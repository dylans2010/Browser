import Foundation
import WebKit

struct MuteTabTool {
    static func execute(webView: WKWebView, mute: Bool) {
        if mute {
            self.mute(in: webView)
        } else {
            unmute(in: webView)
        }
    }

    static func mute(in webView: WKWebView) {
        webView.evaluateJavaScript(
            "document.querySelectorAll('video, audio').forEach(function(el){ el.muted = true; });"
        )
    }

    static func unmute(in webView: WKWebView) {
        webView.evaluateJavaScript(
            "document.querySelectorAll('video, audio').forEach(function(el){ el.muted = false; });"
        )
    }
}
