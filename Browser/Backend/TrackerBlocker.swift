import Foundation
import WebKit

class TrackerBlocker: NSObject, WKNavigationDelegate {
    static let shared = TrackerBlocker()
    private let blockedDomains = ["analytics.google.com", "facebook.net", "doubleclick.net", "segment.io"]

    func shouldBlock(request: URLRequest) -> Bool {
        guard let host = request.url?.host else { return false }
        return blockedDomains.contains { host.contains($0) }
    }
}
