import SwiftUI

struct WebsiteStyleView: View {
    @EnvironmentObject var styleManager: WebsiteStyleManager
    @Environment(\.dismiss) var dismiss

    var domain: String
    @State private var currentStyle = WebsiteStyle()
    private var normalizedDomain: String { domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Text Color")) {
                    ColorPicker("Font Color", selection: Binding(
                        get: { Color(hex: currentStyle.fontColor) },
                        set: { currentStyle.fontColor = $0.toHex() ?? "#000000" }
                    ))
                }

                Section(header: Text("Background Color")) {
                    ColorPicker("Background Color", selection: Binding(
                        get: { Color(hex: currentStyle.backgroundColor) },
                        set: { currentStyle.backgroundColor = $0.toHex() ?? "#FFFFFF" }
                    ))
                }

                Section(header: Text("Font Size (%)")) {
                    HStack {
                        Slider(value: $currentStyle.fontSize, in: 50...300, step: 10)
                        Text("\(Int(currentStyle.fontSize))%")
                            .frame(width: 50)
                    }
                }
            }
            .navigationTitle("Style: \(normalizedDomain.isEmpty ? "Website" : normalizedDomain)")
            .onAppear {
                currentStyle = styleManager.getStyle(for: normalizedDomain)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        styleManager.setStyle(currentStyle, for: normalizedDomain)
                        dismiss()
                    }
                    .disabled(normalizedDomain.isEmpty)
                }
            }
        }
    }
}
