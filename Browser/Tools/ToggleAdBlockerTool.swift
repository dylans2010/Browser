import Foundation

struct ToggleAdBlockerTool {
    static func execute(for host: String) {
        _ = toggle(for: host)
    }

    private static let key = "adBlockerDisabledSites"

    static func isDisabled(for host: String) -> Bool {
        let sites = UserDefaults.standard.stringArray(forKey: key) ?? []
        return sites.contains(host)
    }

    static func toggle(for host: String) -> Bool {
        var sites = UserDefaults.standard.stringArray(forKey: key) ?? []
        if let idx = sites.firstIndex(of: host) {
            sites.remove(at: idx)
            UserDefaults.standard.set(sites, forKey: key)
            return false // ad blocker re-enabled
        } else {
            sites.append(host)
            UserDefaults.standard.set(sites, forKey: key)
            return true // ad blocker disabled for site
        }
    }
}
