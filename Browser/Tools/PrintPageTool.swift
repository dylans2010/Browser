import UIKit
import WebKit

struct PrintPageTool {
    static func execute(webView: WKWebView) {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = webView.title ?? "Web Page"
        printController.printInfo = printInfo
        printController.printFormatter = webView.viewPrintFormatter()

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            printController.present(from: rootVC.view.bounds, in: rootVC.view, animated: true, completionHandler: nil)
        }
    }
}
