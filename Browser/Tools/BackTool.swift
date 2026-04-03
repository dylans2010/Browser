import Foundation
import WebKit

@available(iOS 16.0, *)
struct BackTool {
    static func execute(viewModel: BrowserViewModel) {
        viewModel.goBack()
    }
}
