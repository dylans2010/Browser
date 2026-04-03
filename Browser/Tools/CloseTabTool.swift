import Foundation

@available(iOS 16.0, *)
struct CloseTabTool {
    static func execute(viewModel: BrowserViewModel, id: UUID) {
        viewModel.removeTab(id: id)
    }
}
