import SwiftUI

struct CommandPaletteView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BrowserViewModel
    @State private var searchText = ""

    let commands: [(String, String, () -> Void)]

    init(viewModel: BrowserViewModel, actions: [(String, String, () -> Void)]) {
        self.viewModel = viewModel
        self.commands = actions
    }

    var filteredCommands: [(String, String, () -> Void)] {
        if searchText.isEmpty { return commands }
        return commands.filter { $0.0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            List(filteredCommands, id: \.0) { command in
                Button(action: {
                    command.2()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: command.1)
                        Text(command.0)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Type a command...")
            .navigationTitle("Command Palette")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
