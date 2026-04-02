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
}
