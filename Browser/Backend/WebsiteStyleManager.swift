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
        guard let normalizedDomain = normalizedDomain(from: domain) else { return }
        styles[normalizedDomain] = sanitizedStyle(style)
        saveData()
    }

    func getStyle(for domain: String) -> WebsiteStyle {
        guard let normalizedDomain = normalizedDomain(from: domain) else { return WebsiteStyle() }
        return sanitizedStyle(styles[normalizedDomain] ?? WebsiteStyle())
    }

    func getInjectionScript(for domain: String) -> String {
        guard let normalizedDomain = normalizedDomain(from: domain),
              let existingStyle = styles[normalizedDomain] else { return "" }
        let style = sanitizedStyle(existingStyle)

        guard let fontColorData = try? JSONSerialization.data(withJSONObject: style.fontColor),
              let backgroundColorData = try? JSONSerialization.data(withJSONObject: style.backgroundColor),
              let fontColorJSON = String(data: fontColorData, encoding: .utf8),
              let backgroundColorJSON = String(data: backgroundColorData, encoding: .utf8) else {
            return ""
        }

        return """
        (function() {
            const fontColor = \(fontColorJSON);
            const backgroundColor = \(backgroundColorJSON);
            const fontSize = \(style.fontSize);
            const css = `
                body {
                    color: ${fontColor} !important;
                    background-color: ${backgroundColor} !important;
                    font-size: ${fontSize}% !important;
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

    func normalizedDomain(from domain: String?) -> String? {
        guard let domain else { return nil }
        let normalized = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
    }

    private func sanitizedStyle(_ style: WebsiteStyle) -> WebsiteStyle {
        WebsiteStyle(
            fontColor: sanitizeHexColor(style.fontColor, fallback: "#000000"),
            backgroundColor: sanitizeHexColor(style.backgroundColor, fallback: "#FFFFFF"),
            fontSize: sanitizeFontSize(style.fontSize)
        )
    }

    private func sanitizeFontSize(_ value: Double) -> Double {
        guard value.isFinite else { return 100.0 }
        return min(max(value, 50.0), 300.0)
    }

    private func sanitizeHexColor(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let hex = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        let allowed = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        let isValidLength = hex.count == 3 || hex.count == 6
        let isValidChars = hex.rangeOfCharacter(from: allowed.inverted) == nil
        guard isValidLength, isValidChars else { return fallback }
        return "#\(hex.uppercased())"
    }

    private func saveData() {
        if let encoded = try? JSONEncoder().encode(styles) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: WebsiteStyle].self, from: data) {
            styles = decoded.reduce(into: [:]) { partialResult, pair in
                guard let domain = normalizedDomain(from: pair.key) else { return }
                partialResult[domain] = sanitizedStyle(pair.value)
            }
        }
    }
}
