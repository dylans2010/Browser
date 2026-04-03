import Foundation
import WebKit

struct ClearSiteCacheTool {
    static func execute(for webView: WKWebView, completion: @escaping () -> Void) {
        guard let host = webView.url?.host else {
            completion()
            return
        }
        let store = webView.configuration.websiteDataStore
        let cacheTypes: Set<String> = [
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeOfflineWebApplicationCache
        ]
        store.fetchDataRecords(ofTypes: cacheTypes) { records in
            let siteRecords = records.filter { $0.displayName.contains(host) }
            store.removeData(ofTypes: cacheTypes, for: siteRecords) {
                DispatchQueue.main.async { completion() }
            }
        }
    }
}
