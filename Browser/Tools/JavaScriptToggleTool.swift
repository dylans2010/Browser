import Foundation
import WebKit

struct JavaScriptToggleTool {
    static func execute(in webView: WKWebView, isEnabled: Bool) {
        if #available(iOS 14.0, macOS 11.0, *) {
            let preferences = WKWebpagePreferences()
            preferences.allowsContentJavaScript = isEnabled
            webView.configuration.defaultWebpagePreferences = preferences
        } else {
            webView.configuration.preferences.javaScriptEnabled = isEnabled
        }
        webView.reload()
    }

    static func toggle(in webView: WKWebView) {
        if #available(iOS 14.0, macOS 11.0, *) {
            let current = webView.configuration.defaultWebpagePreferences.allowsContentJavaScript
            execute(in: webView, isEnabled: !current)
        } else {
            let current = webView.configuration.preferences.javaScriptEnabled
            execute(in: webView, isEnabled: !current)
        }
    }
}
