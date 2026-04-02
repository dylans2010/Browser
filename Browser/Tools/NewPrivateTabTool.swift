import Foundation

struct NewPrivateTabTool {
    static func execute(viewModel: BrowserViewModel) {
        viewModel.addTab(isEphemeral: true)
    }
}
