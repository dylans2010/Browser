import Foundation

struct NewTabTool {
    static func execute(viewModel: BrowserViewModel) {
        viewModel.addTab()
    }
}
