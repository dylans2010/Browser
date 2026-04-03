import Foundation

@available(iOS 16.0, *)
struct NewPrivateTabTool {
    static func execute(viewModel: BrowserViewModel) {
        viewModel.addTab(isEphemeral: true)
    }
}
