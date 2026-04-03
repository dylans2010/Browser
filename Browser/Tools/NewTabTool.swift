import Foundation

@available(iOS 16.0, *)
struct NewTabTool {
    static func execute(viewModel: BrowserViewModel) {
        viewModel.addTab()
    }
}
