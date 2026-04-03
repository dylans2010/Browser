import Foundation
import WebKit

struct TabItem: Identifiable {
    let id = UUID()
    var url: URL?
    var title: String = "New Tab"
    var webView: WKWebView
    var isEphemeral: Bool = false

    init(url: URL? = nil, isEphemeral: Bool = false) {
        self.url = url
        self.isEphemeral = isEphemeral

        let config = WKWebViewConfiguration()
        if isEphemeral {
            config.websiteDataStore = .nonPersistent()
        }

        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.isFindInteractionEnabled = true
    }
}
