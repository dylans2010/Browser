import Foundation
import WebKit

struct InspectElementTool {
    struct DOMInfo {
        let tagCount: Int
        let scriptCount: Int
        let linkCount: Int
        let imageCount: Int
        let iframeCount: Int
        let title: String
        let charset: String
    }

    static func inspect(webView: WKWebView, completion: @escaping (DOMInfo) -> Void) {
        let js = """
        JSON.stringify({
            tagCount: document.getElementsByTagName('*').length,
            scriptCount: document.scripts.length,
            linkCount: document.links.length,
            imageCount: document.images.length,
            iframeCount: document.querySelectorAll('iframe').length,
            title: document.title,
            charset: document.characterSet
        });
        """
        webView.evaluateJavaScript(js) { result, _ in
            guard let jsonStr = result as? String,
                  let data = jsonStr.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async {
                    completion(DOMInfo(tagCount: 0, scriptCount: 0, linkCount: 0,
                                       imageCount: 0, iframeCount: 0, title: "", charset: ""))
                }
                return
            }
            let info = DOMInfo(
                tagCount: dict["tagCount"] as? Int ?? 0,
                scriptCount: dict["scriptCount"] as? Int ?? 0,
                linkCount: dict["linkCount"] as? Int ?? 0,
                imageCount: dict["imageCount"] as? Int ?? 0,
                iframeCount: dict["iframeCount"] as? Int ?? 0,
                title: dict["title"] as? String ?? "",
                charset: dict["charset"] as? String ?? ""
            )
            DispatchQueue.main.async { completion(info) }
        }
    }
}
