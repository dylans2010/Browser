import SwiftUI

@available(iOS 16.0, *)
struct TabGridView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BrowserViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.tabs) { tab in
                        VStack {
                            ZStack {
                                if let snapshot = tab.snapshot {
                                    Image(uiImage: snapshot)
                                        .resizable()
                                        .aspectRatio(3/4, contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .cornerRadius(12)
                                        .clipped()
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                        .aspectRatio(3/4, contentMode: .fit)

                                    Text(tab.title)
                                        .font(.caption)
                                        .padding(8)
                                }

                                if tab.id == viewModel.activeTabId {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue, lineWidth: 3)
                                }
                            }
                            .onTapGesture {
                                viewModel.activeTabId = tab.id
                                dismiss()
                            }

                            HStack {
                                Text(tab.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Button(action: { viewModel.removeTab(id: tab.id) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Tabs")
            .toolbar {
                Group {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { viewModel.addTab() }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
    }
}
