import SwiftUI

struct InspectElementView: View {
    let domInfo: InspectElementTool.DOMInfo

    var body: some View {
        NavigationView {
            List {
                Section("Page") {
                    row(label: "Title", value: domInfo.title.isEmpty ? "—" : domInfo.title)
                    row(label: "Charset", value: domInfo.charset.isEmpty ? "—" : domInfo.charset)
                }
                Section("DOM Stats") {
                    row(label: "Total Elements", value: "\(domInfo.tagCount)")
                    row(label: "Scripts", value: "\(domInfo.scriptCount)")
                    row(label: "Links", value: "\(domInfo.linkCount)")
                    row(label: "Images", value: "\(domInfo.imageCount)")
                    row(label: "Iframes", value: "\(domInfo.iframeCount)")
                }
            }
            .navigationTitle("Inspect Element")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func row(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
