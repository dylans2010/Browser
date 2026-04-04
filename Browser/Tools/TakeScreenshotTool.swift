import UIKit
import WebKit

struct TakeScreenshotTool {
    static func execute(webView: WKWebView, completion: @escaping (UIImage?) -> Void) {
        let configuration = WKWebViewConfiguration()
        let snapshotConfiguration = WKSnapshotConfiguration()

        webView.takeSnapshot(with: snapshotConfiguration) { image, error in
            if let image = image {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                completion(image)
            } else {
                completion(nil)
            }
        }
    }
}
