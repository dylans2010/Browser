import Foundation

struct PrivacyReportTool {
    static func execute() -> PrivacyReport {
        // Mocked for now based on TrackerBlocker's knowledge
        return PrivacyReport(
            blockedTrackers: ["Google Analytics", "Facebook Pixel", "Segment", "Double Click"],
            trackersFound: 4
        )
    }
}

struct PrivacyReport: Identifiable {
    let id = UUID()
    let blockedTrackers: [String]
    let trackersFound: Int
}
