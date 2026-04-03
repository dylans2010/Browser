import Foundation
import WebKit

struct PictureInPictureTool {
    static func execute(in webView: WKWebView) {
        let js = """
        (function() {
            var video = document.querySelector('video');
            if (video && document.pictureInPictureEnabled) {
                if (document.pictureInPictureElement) {
                    document.exitPictureInPicture();
                } else {
                    video.requestPictureInPicture().catch(function(e) { console.warn('PiP error:', e); });
                }
            }
        })();
        """
        webView.evaluateJavaScript(js)
    }
}
