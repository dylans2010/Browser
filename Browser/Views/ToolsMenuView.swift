import SwiftUI

struct ToolsMenuView: View {
    let tools: [ToolItem]
    let onSelect: (ToolItem) -> Void

    private var groupedTools: [(ToolCategory, [ToolItem])] {
        let grouped = Dictionary(grouping: tools) { $0.category }
        return ToolCategory.allCases.compactMap { category in
            guard let values = grouped[category], !values.isEmpty else { return nil }
            return (category, values)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(groupedTools, id: \.0) { category, tools in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.rawValue)
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(tools) { tool in
                                Button {
                                    onSelect(tool)
                                } label: {
                                    HStack {
                                        Image(systemName: tool.icon)
                                            .foregroundColor(.accentColor)
                                            .frame(width: 24)
                                        Text(tool.title)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemBackground).opacity(0.4))
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Tools")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
