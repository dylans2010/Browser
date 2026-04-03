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

        // Keep domain + at most one path component (strip query string from display)
        // Split on "/" to get path components
        let parts = result.components(separatedBy: "/")

        // Strip query string from the last kept component
        if parts.count > 1 {
            var secondPart = parts[1]
            if let qmark = secondPart.range(of: "?") {
                secondPart = String(secondPart[secondPart.startIndex..<qmark.lowerBound])
            }
            if secondPart.isEmpty {
                result = parts[0]
            } else {
                result = parts[0] + "/" + secondPart
            }
        } else {
            // Only domain, strip query string
            if let qmark = result.range(of: "?") {
                result = String(result[result.startIndex..<qmark.lowerBound])
            }
            // Strip trailing slash
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
}
