import Foundation

struct URLFormatter {
    /// Returns a compact display string for a URL.
    /// Strips scheme (https://, http://) and www. prefix,
    /// then shows only the domain + first path component.
    /// Example: https://www.google.com/search?q=test → google.com/search
    /// Example: https://github.com/user/repo/issues/123 → github.com/user
    static func formatted(_ urlString: String) -> String {
        guard !urlString.isEmpty else { return urlString }

        var result = urlString

        if UserDefaults.standard.bool(forKey: "removeTrackingParameters") {
            result = NoTrackingParameters.clean(result)
        }

        // Strip common scheme+www prefixes
        for prefix in ["https://www.", "http://www.", "https://", "http://"] {
            if result.hasPrefix(prefix) {
                result = String(result.dropFirst(prefix.count))
                break
            }
        }

        // Remove fragment
        if let hashRange = result.range(of: "#") {
            result = String(result[result.startIndex..<hashRange.lowerBound])
        }

        // Keep domain + at most one path component
        let parts = result.components(separatedBy: "/")
        if parts.count > 1 {
            let secondPart = stripQueryString(from: parts[1])
            result = secondPart.isEmpty ? parts[0] : parts[0] + "/" + secondPart
        } else {
            result = stripQueryString(from: result)
            if result.hasSuffix("/") {
                result = String(result.dropLast())
            }
        }

        return result
    }

    /// Returns true if the URL uses HTTPS.
    static func isSecure(_ urlString: String) -> Bool {
        return urlString.lowercased().hasPrefix("https://")
    }

    // MARK: - Private helpers

    private static func stripQueryString(from string: String) -> String {
        if let qmark = string.range(of: "?") {
            return String(string[string.startIndex..<qmark.lowerBound])
        }
        return string
    }
}
