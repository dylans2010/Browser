import Foundation
import WebKit
import SwiftUI

@available(iOS 16.0, *)
struct TabItem: Identifiable {
    let id = UUID()
    var url: URL?
    var title: String = "New Tab"
    var webView: WKWebView
    var snapshot: UIImage?
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
