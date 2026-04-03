import Foundation

@available(iOS 16.0, *)
struct CloseOtherTabsTool {
    static func execute(viewModel: BrowserViewModel) {
        viewModel.closeOtherTabs()
    }
}
