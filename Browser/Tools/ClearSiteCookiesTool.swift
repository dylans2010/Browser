import Foundation
import WebKit

struct ClearSiteCookiesTool {
    static func execute(for webView: WKWebView, completion: @escaping () -> Void) {
        guard let host = webView.url?.host else {
            completion()
            return
        }
        let store = webView.configuration.websiteDataStore
        let dataTypes: Set<String> = [WKWebsiteDataTypeCookies]
        store.fetchDataRecords(ofTypes: dataTypes) { records in
            let siteRecords = records.filter { $0.displayName.contains(host) }
            store.removeData(ofTypes: dataTypes, for: siteRecords) {
                DispatchQueue.main.async { completion() }
            }
        }
    }
}
