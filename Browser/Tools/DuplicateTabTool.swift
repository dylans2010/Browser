import Foundation

@available(iOS 16.0, *)
struct DuplicateTabTool {
    static func execute(viewModel: BrowserViewModel) {
        viewModel.duplicateTab()
    }
}
