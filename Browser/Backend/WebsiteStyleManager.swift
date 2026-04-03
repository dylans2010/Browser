import Foundation
import SwiftUI

struct WebsiteStyle: Codable {
    var fontColor: String = "#000000"
    var backgroundColor: String = "#FFFFFF"
    var fontSize: Double = 100.0 // Percentage
}

class WebsiteStyleManager: ObservableObject {
    @Published var styles: [String: WebsiteStyle] = [:] // Domain: Style

    private let storageKey = "website_styles"

    init() {
        loadData()
    }

    func setStyle(_ style: WebsiteStyle, for domain: String) {
        styles[domain] = style
        saveData()
    }

    func getStyle(for domain: String) -> WebsiteStyle {
        return styles[domain] ?? WebsiteStyle()
    }

    func getInjectionScript(for domain: String) -> String {
        guard let style = styles[domain] else { return "" }
        return """
        (function() {
            const css = `
                body {
                    color: \(style.fontColor) !important;
                    background-color: \(style.backgroundColor) !important;
                    font-size: \(style.fontSize)% !important;
                }
                * {
                    color: inherit !important;
                    background-color: inherit !important;
                }
            `;
            const style = document.createElement('style');
            style.innerHTML = css;
            document.head.appendChild(style);
        })();
        """
    }

    private func saveData() {
        if let encoded = try? JSONEncoder().encode(styles) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: WebsiteStyle].self, from: data) {
            styles = decoded
        }
    }
}
