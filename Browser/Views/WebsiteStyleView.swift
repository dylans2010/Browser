import SwiftUI

struct WebsiteStyleView: View {
    @EnvironmentObject var styleManager: WebsiteStyleManager
    @Environment(\.dismiss) var dismiss

    var domain: String
    @State private var currentStyle = WebsiteStyle()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Colors")) {
                    ColorPicker("Font Color", selection: Binding(
                        get: { Color(hex: currentStyle.fontColor) },
                        set: { currentStyle.fontColor = $0.toHex() ?? "#000000" }
                    ))
                    ColorPicker("Background Color", selection: Binding(
                        get: { Color(hex: currentStyle.backgroundColor) },
                        set: { currentStyle.backgroundColor = $0.toHex() ?? "#FFFFFF" }
                    ))
                }

                Section(header: Text("Typography")) {
                    VStack(alignment: .leading) {
                        Text("Font Size: \(Int(currentStyle.fontSize))%")
                        Slider(value: $currentStyle.fontSize, in: 50...300, step: 10)
                    }

                    Picker("Font Family", selection: $currentStyle.fontFamily) {
                        Text("System").tag("system-ui")
                        Text("Serif").tag("serif")
                        Text("Sans-Serif").tag("sans-serif")
                        Text("Monospace").tag("monospace")
                        Text("Cursive").tag("cursive")
                    }

                    VStack(alignment: .leading) {
                        Text("Line Height: \(currentStyle.lineHeight, specifier: "%.1f")")
                        Slider(value: $currentStyle.lineHeight, in: 0.5...3.0, step: 0.1)
                    }

                    VStack(alignment: .leading) {
                        Text("Letter Spacing: \(currentStyle.letterSpacing, specifier: "%.1f")px")
                        Slider(value: $currentStyle.letterSpacing, in: -2.0...10.0, step: 0.5)
                    }
                }

                Section(header: Text("Visual Filters")) {
                    VStack(alignment: .leading) {
                        Text("Contrast: \(Int(currentStyle.contrast))%")
                        Slider(value: $currentStyle.contrast, in: 50...200, step: 10)
                    }

                    VStack(alignment: .leading) {
                        Text("Grayscale: \(Int(currentStyle.grayscale))%")
                        Slider(value: $currentStyle.grayscale, in: 0...100, step: 5)
                    }

                    VStack(alignment: .leading) {
                        Text("Invert: \(Int(currentStyle.invert))%")
                        Slider(value: $currentStyle.invert, in: 0...100, step: 5)
                    }
                }

                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        currentStyle = WebsiteStyle()
                    }
                }
            }
            .navigationTitle("Style: \(domain)")
            .onAppear {
                currentStyle = styleManager.getStyle(for: domain)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        styleManager.setStyle(currentStyle, for: domain)
                        dismiss()
                    }
                }
            }
        }
    }
}

