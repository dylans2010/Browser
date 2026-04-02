import Foundation

struct CloseTabTool {
    static func execute(viewModel: BrowserViewModel, id: UUID) {
        viewModel.removeTab(id: id)
    }
}
