import Foundation

@available(iOS 16.0, *)
struct CloseAllTabsTool {
    static func execute(viewModel: BrowserViewModel) {
        let ids = viewModel.tabs.map { $0.id }
        for id in ids {
            viewModel.removeTab(id: id)
        }
    }
}
