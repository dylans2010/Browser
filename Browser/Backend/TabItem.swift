import Foundation
import WebKit
import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

@available(iOS 16.0, *)
class TabItem: Identifiable, Codable {
    var id = UUID()
    var url: URL?
    var title: String = "New Tab"
    var isEphemeral: Bool = false
    var groupId: UUID?
    var createdAt: Date = Date()
    var snapshot: PlatformImage?

    var webView: WKWebView = WKWebView()

    init(url: URL? = nil, isEphemeral: Bool = false, groupId: UUID? = nil) {
        self.url = url
        self.isEphemeral = isEphemeral
        self.groupId = groupId
        self.setupWebView()
    }

    func setupWebView() {
        let config = WKWebViewConfiguration()
        if isEphemeral {
            config.websiteDataStore = .nonPersistent()
        }
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.isFindInteractionEnabled = true
    }

    // Codable support
    enum CodingKeys: String, CodingKey {
        case id, url, title, isEphemeral, groupId, createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        title = try container.decode(String.self, forKey: .title)
        isEphemeral = try container.decode(Bool.self, forKey: .isEphemeral)
        groupId = try container.decodeIfPresent(UUID.self, forKey: .groupId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        setupWebView()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(title, forKey: .title)
        try container.encode(isEphemeral, forKey: .isEphemeral)
        try container.encode(groupId, forKey: .groupId)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
