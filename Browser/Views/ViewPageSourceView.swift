import SwiftUI

struct ViewPageSourceView: View {
    let source: String
    @State private var searchText = ""

    private var displayedSource: String {
        if searchText.isEmpty { return source }
        // Highlight (just return source filtered by lines containing the search text)
        return source.components(separatedBy: "\n")
            .filter { $0.localizedCaseInsensitiveContains(searchText) }
            .joined(separator: "\n")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                Text(displayedSource)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Page Source")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Filter source")
        }
    }
}
