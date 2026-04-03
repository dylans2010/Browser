import Foundation
import SwiftUI

struct WebsiteStyle: Codable {
    var fontColor: String = "#000000"
    var backgroundColor: String = "#FFFFFF"
    var fontSize: Double = 100.0 // Percentage
    var fontFamily: String = "system-ui"
    var lineHeight: Double = 1.5
    var letterSpacing: Double = 0.0
    var contrast: Double = 100.0
    var grayscale: Double = 0.0
    var invert: Double = 0.0
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
              let fontFamilyData = try? JSONSerialization.data(withJSONObject: style.fontFamily),
              let fontColorJSON = String(data: fontColorData, encoding: .utf8),
              let backgroundColorJSON = String(data: backgroundColorData, encoding: .utf8),
              let fontFamilyJSON = String(data: fontFamilyData, encoding: .utf8) else {
            return ""
        }

        return """
        (function() {
            const fontColor = \(fontColorJSON);
            const backgroundColor = \(backgroundColorJSON);
            const fontFamily = \(fontFamilyJSON);
            const fontSize = \(style.fontSize);
            const lineHeight = \(style.lineHeight);
            const letterSpacing = \(style.letterSpacing);
            const contrast = \(style.contrast);
            const grayscale = \(style.grayscale);
            const invert = \(style.invert);

            const css = `
                html {
                    filter: contrast(${contrast}%) grayscale(${grayscale}%) invert(${invert}%) !important;
                }
                body {
                    color: ${fontColor} !important;
                    background-color: ${backgroundColor} !important;
                    font-size: ${fontSize}% !important;
                    font-family: ${fontFamily} !important;
                    line-height: ${lineHeight} !important;
                    letter-spacing: ${letterSpacing}px !important;
                }
                * {
                    color: inherit !important;
                    background-color: inherit !important;
                    font-family: inherit !important;
                }
            `;
            const styleId = 'custom-website-style';
            let styleElement = document.getElementById(styleId);
            if (!styleElement) {
                styleElement = document.createElement('style');
                styleElement.id = styleId;
                document.head.appendChild(styleElement);
            }
            styleElement.innerHTML = css;
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
            fontSize: sanitizeFontSize(style.fontSize),
            fontFamily: style.fontFamily,
            lineHeight: max(0.5, min(style.lineHeight, 5.0)),
            letterSpacing: max(-5.0, min(style.letterSpacing, 20.0)),
            contrast: max(0.0, min(style.contrast, 500.0)),
            grayscale: max(0.0, min(style.grayscale, 100.0)),
            invert: max(0.0, min(style.invert, 100.0))
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
