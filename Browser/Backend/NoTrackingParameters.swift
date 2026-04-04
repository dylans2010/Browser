import Foundation

struct NoTrackingParameters {
    static let trackingParameters = [
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "utm_id", "utm_source_platform", "utm_creative_format", "utm_marketing_tactic",
        "fbclid", "gclid", "gclsrc", "dclid", "msclkid", "twclid", "igshid", "igsh",
        "mc_eid", "tracking_id", "ref", "ref_", "ref_src", "ref_url", "_hsenc", "_hsmi", "mkt_tok", "yclid", "_openstat"
    ]

    static func clean(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        guard let queryItems = components.queryItems else { return url }

        let filteredItems = queryItems.filter { item in
            let name = item.name.lowercased()

            // Explicitly block known tracking parameters
            if trackingParameters.contains(name) {
                return false
            }

            // Advanced logic: Remove long random-looking strings if they are likely tracking IDs
            if let value = item.value, isLikelyTrackingID(value) {
                return false
            }

            return true
        }

        components.queryItems = filteredItems.isEmpty ? nil : filteredItems
        return components.url ?? url
    }

    static func clean(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else { return urlString }
        return clean(url).absoluteString
    }

    private static func isLikelyTrackingID(_ value: String) -> Bool {
        // Tracking IDs are often long hex or base64-like strings
        // E.g., longer than 20 chars and mixture of alphanum
        if value.count > 24 {
            let letters = CharacterSet.letters
            let digits = CharacterSet.decimalDigits
            if value.rangeOfCharacter(from: letters) != nil && value.rangeOfCharacter(from: digits) != nil {
                return true
            }
        }
        return false
    }
}
