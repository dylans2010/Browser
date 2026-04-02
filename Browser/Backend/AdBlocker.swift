import Foundation

class AdBlocker {
    static let shared = AdBlocker()

    // A simple list of known ad domains
    private let adDomains: Set<String> = [
        "doubleclick.net",
        "googleadservices.com",
        "googlesyndication.com",
        "moatads.com",
        "adnxs.com",
        "adservice.google.com",
        "adform.net",
        "advertising.com",
        "taboola.com",
        "outbrain.com",
        "amazon-adsystem.com",
        "serving-sys.com",
        "quantserve.com",
        "scorecardresearch.com"
    ]

    func shouldBlock(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }

        for adDomain in adDomains {
            if host == adDomain || host.hasSuffix("." + adDomain) {
                return true
            }
        }

        return false
    }
}
