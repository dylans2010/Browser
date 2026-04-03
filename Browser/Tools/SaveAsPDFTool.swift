import Foundation
import WebKit
#if os(iOS)
import UIKit
#endif

struct SaveAsPDFTool {
    static func execute(webView: WKWebView, completion: @escaping (URL?) -> Void) {
        let config = WKPDFConfiguration()
        config.rect = webView.bounds
        webView.createPDF(configuration: config) { result in
            switch result {
            case .success(let data):
                let tmpURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("page_\(Int(Date().timeIntervalSince1970)).pdf")
                do {
                    try data.write(to: tmpURL)
                    DispatchQueue.main.async { completion(tmpURL) }
                } catch {
                    DispatchQueue.main.async { completion(nil) }
                }
            case .failure:
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
}
