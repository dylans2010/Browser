import Foundation
import Combine

struct DomainUsage: Codable {
    var frequency: Int
    var totalTimeSpent: TimeInterval
}

struct NoteAssociation: Codable {
    var keywords: [String]
    var domain: String
}

class AutoNotesLearning: ObservableObject {
    static let shared = AutoNotesLearning()

    @Published var domainStats: [String: DomainUsage] = [:]
    @Published var keywordAssociations: [String: [String]] = [:] // Keyword -> [Domains]

    private let statsKey = "auto_notes_domain_stats"
    private let associationsKey = "auto_notes_associations"

    private var lastVisitStartTime: [String: Date] = [:]

    init() {
        loadData()
    }

    func trackVisit(url: URL?) {
        guard let host = url?.host else { return }

        var stats = domainStats[host] ?? DomainUsage(frequency: 0, totalTimeSpent: 0)
        stats.frequency += 1
        domainStats[host] = stats

        lastVisitStartTime[host] = Date()
        saveData()
    }

    func trackTimeSpent(url: URL?) {
        guard let host = url?.host, let startTime = lastVisitStartTime[host] else { return }

        let timeSpent = Date().timeIntervalSince(startTime)
        var stats = domainStats[host] ?? DomainUsage(frequency: 0, totalTimeSpent: 0)
        stats.totalTimeSpent += timeSpent
        domainStats[host] = stats

        lastVisitStartTime.removeValue(forKey: host)
        saveData()
    }

    func learnFromNote(content: String, domain: String) {
        let keywords = extractKeywords(from: content)
        for keyword in keywords {
            var domains = keywordAssociations[keyword] ?? []
            if !domains.contains(domain) {
                domains.append(domain)
                keywordAssociations[keyword] = domains
            }
        }
        saveData()
    }

    func getLearnedContext(for domain: String) -> String {
        let relevantKeywords = keywordAssociations.filter { $0.value.contains(domain) }.map { $0.key }
        if relevantKeywords.isEmpty {
            return "No specific interests learned for this domain yet."
        }
        return "Learned interests for this domain: \(relevantKeywords.joined(separator: ", "))."
    }

    private func extractKeywords(from text: String) -> [String] {
        let stopWords = Set(["the", "and", "a", "of", "to", "in", "is", "it", "that", "was", "for", "on", "are", "with", "as", "at", "be", "this", "have", "from", "by", "not", "or", "but"])
        let words = text.lowercased().components(separatedBy: .punctuationCharacters).joined().components(separatedBy: .whitespacesAndNewlines)

        let filtered = words.filter { $0.count > 3 && !stopWords.contains($0) }

        // Count frequencies
        var counts: [String: Int] = [:]
        for word in filtered {
            counts[word, default: 0] += 1
        }

        return Array(counts.keys.sorted { counts[$0]! > counts[$1]! }.prefix(5))
    }

    private func saveData() {
        if let encodedStats = try? JSONEncoder().encode(domainStats) {
            UserDefaults.standard.set(encodedStats, forKey: statsKey)
        }
        if let encodedAssoc = try? JSONEncoder().encode(keywordAssociations) {
            UserDefaults.standard.set(encodedAssoc, forKey: associationsKey)
        }
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode([String: DomainUsage].self, from: data) {
            domainStats = decoded
        }
        if let data = UserDefaults.standard.data(forKey: associationsKey),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            keywordAssociations = decoded
        }
    }
}
