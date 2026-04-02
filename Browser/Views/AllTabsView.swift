import SwiftUI

struct AllTabsView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                    ForEach(viewModel.tabs) { tab in
                        VStack {
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 120)
                                    .overlay(
                                        Text(tab.title)
                                            .font(.caption)
                                            .padding(8)
                                    )

                                Button(action: {
                                    viewModel.removeTab(id: tab.id)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .padding(4)
                                }
                                .buttonStyle(.plain)
                            }

                            Text(tab.title)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .onTapGesture {
                            viewModel.activeTabId = tab.id
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("All Tabs")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
