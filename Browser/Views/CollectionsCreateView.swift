import SwiftUI

@available(iOS 16.0, *)
struct CollectionsCreateView: View {
    @EnvironmentObject var collectionsManager: CollectionsManager
    @EnvironmentObject var browserViewModel: BrowserViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var color: Color = .blue
    @State private var selectedSymbol: String = "folder"
    @State private var selectedTabIDs: Set<UUID> = []

    let symbols = ["folder", "star", "bookmark", "globe", "heart", "cloud", "bag", "cart", "person", "music.note"]

    var body: some View {
        NavigationView {
            Form {
                Section("Information") {
                    TextField("Name", text: $name)
                    ColorPicker("Color", selection: $color)
                }

                Section("Symbol") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(symbols, id: \.self) { symbol in
                                Image(systemName: symbol)
                                    .font(.title2)
                                    .padding(10)
                                    .background(selectedSymbol == symbol ? color.opacity(0.2) : Color.clear)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(selectedSymbol == symbol ? color : Color.clear, lineWidth: 2))
                                    .onTapGesture { selectedSymbol = symbol }
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }

                Section("Select Tabs to Include") {
                    if browserViewModel.tabs.isEmpty {
                        Text("No active tabs")
                            .foregroundColor(.secondary)
                    } else {
                        List(browserViewModel.tabs) { tab in
                            HStack {
                                Text(tab.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                if selectedTabIDs.contains(tab.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(color)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedTabIDs.contains(tab.id) {
                                    selectedTabIDs.remove(tab.id)
                                } else {
                                    selectedTabIDs.insert(tab.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Collection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let urls = browserViewModel.tabs.filter { selectedTabIDs.contains($0.id) }.compactMap { $0.url?.absoluteString }
                        collectionsManager.addCollection(name: name, color: colorToHex(color), sfSymbol: selectedSymbol, urls: urls)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func colorToHex(_ color: Color) -> String {
        #if os(iOS)
        guard let components = UIColor(color).cgColor.components else { return "#0000FF" }
        #else
        guard let components = NSColor(color).cgColor.components else { return "#0000FF" }
        #endif
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
