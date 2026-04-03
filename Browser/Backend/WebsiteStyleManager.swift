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
        let key = normalizeDomain(domain)
        guard !key.isEmpty else { return }
        var normalizedStyle = style
        normalizedStyle.fontSize = min(max(normalizedStyle.fontSize, 50), 300)
        styles[key] = normalizedStyle
        saveData()
    }

    func getStyle(for domain: String) -> WebsiteStyle {
        let key = normalizeDomain(domain)
        guard !key.isEmpty else { return WebsiteStyle() }
        return styles[key] ?? WebsiteStyle()
    }

    func getInjectionScript(for domain: String) -> String {
        let key = normalizeDomain(domain)
        guard let style = styles[key] else { return "" }
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
            const styleElement = document.createElement('style');
            styleElement.innerHTML = css;
            document.head.appendChild(styleElement);
        })();
        """
    }

    private func normalizeDomain(_ domain: String) -> String {
        domain
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
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
