import SwiftUI
import Foundation
import Security

struct SecurityDetails: Equatable {
let host: String
let isSecureConnection: Bool
let transport: String
let certificateCommonName: String
let issuerSummary: String
let validFrom: Date?
let validTo: Date?
}

struct SecurityDetailsView: View {
let details: SecurityDetails?

var body: some View {
    NavigationView {
        List {
            Section("Connection") {
                row(label: "Status", value: details?.isSecureConnection == true ? "Secure" : "Not Secure")
                row(label: "Host", value: details?.host ?? "—")
                row(label: "Transport", value: details?.transport ?? "—")
            }

            Section("SSL Certificate") {
                row(label: "Common Name", value: details?.certificateCommonName ?? "Unavailable")
                row(label: "Issuer", value: details?.issuerSummary ?? "Unavailable")
                row(label: "Valid From", value: formatted(details?.validFrom))
                row(label: "Valid To", value: formatted(details?.validTo))
            }
        }
        .navigationTitle("Security Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private func row(label: String, value: String) -> some View {
    HStack {
        Text(label)
            .foregroundColor(.secondary)
        Spacer()
        Text(value)
            .multilineTextAlignment(.trailing)
    }
}

private func formatted(_ date: Date?) -> String {
    guard let date else { return "Unavailable" }
    return date.formatted(date: .abbreviated, time: .omitted)
}
```

}

final class SecurityDetailsFetcher: NSObject, URLSessionDataDelegate {
private var completion: ((SecurityDetails?) -> Void)?
private var requestedURL: URL?
private var didFinish = false

```
func fetch(for url: URL, completion: @escaping (SecurityDetails?) -> Void) {
    guard let host = url.host else {
        completion(nil)
        return
    }

    self.completion = completion
    requestedURL = url
    didFinish = false
    var components = URLComponents()
    components.scheme = "https"
    components.host = host
    components.path = "/"

    guard let secureURL = components.url else {
        completion(nil)
        return
    }

    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 8
    let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    session.dataTask(with: secureURL).resume()
}

func urlSession(
    _ session: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
) {
    guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
          let trust = challenge.protectionSpace.serverTrust else {
        completionHandler(.performDefaultHandling, nil)
        return
    }

    var trustError: CFError?
    _ = SecTrustEvaluateWithError(trust, &trustError)

    let certificates = SecTrustCopyCertificateChain(trust) as? [SecCertificate]
    let cert = certificates?.first

    let commonName = cert.flatMap { SecCertificateCopySubjectSummary($0) as String? } ?? "Unavailable"

    // kSecOIDX509V1* and SecCertificateCopyValues are macOS-only and unavailable on iOS.
    // Issuer and validity dates are populated via the remote fallback below.
    var info = SecurityDetails(
        host: challenge.protectionSpace.host,
        isSecureConnection: true,
        transport: challenge.protectionSpace.protocol ?? "HTTPS",
        certificateCommonName: commonName,
        issuerSummary: "Unavailable",
        validFrom: nil,
        validTo: nil
    )

    // Call completionHandler before the async remote fetch so the TLS
    // handshake is not held up waiting for the network request to finish.
    completionHandler(.performDefaultHandling, URLCredential(trust: trust))

    // Always attempt remote fallback on iOS since the Security framework
    // does not expose issuer or validity dates on this platform.
    if let requestedURL {
        fetchRemoteCertificateDetails(for: requestedURL) { [weak self] remote in
            if let remote {
                info = SecurityDetails(
                    host: info.host,
                    isSecureConnection: info.isSecureConnection,
                    transport: info.transport,
                    certificateCommonName: info.certificateCommonName,
                    issuerSummary: remote.issuerSummary,
                    validFrom: remote.validFrom,
                    validTo: remote.validTo
                )
            }
            self?.finish(with: info)
        }
    } else {
        finish(with: info)
    }
}

func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error {
        _ = error
        finish(with: nil)
    }
}

private func finish(with details: SecurityDetails?) {
    guard !didFinish else { return }
    didFinish = true
    DispatchQueue.main.async {
        self.completion?(details)
        self.completion = nil
        self.requestedURL = nil
    }
}

private struct RemoteCertificateDetails {
    let issuerSummary: String
    let validFrom: Date?
    let validTo: Date?
}

private struct AllOriginsResponse: Decodable {
    let contents: String
}

private func fetchRemoteCertificateDetails(for url: URL, completion: @escaping (RemoteCertificateDetails?) -> Void) {
    let encoded = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url.absoluteString
    guard let fetchURL = URL(string: "https://api.allorigins.win/get?url=\(encoded)") else {
        completion(nil)
        return
    }

    URLSession.shared.dataTask(with: fetchURL) { data, _, error in
        guard error == nil, let data else {
            completion(nil)
            return
        }

        guard let response = try? JSONDecoder().decode(AllOriginsResponse.self, from: data) else {
            completion(nil)
            return
        }

        completion(self.parseRemoteCertificateDetails(from: response.contents))
    }.resume()
}

private func parseRemoteCertificateDetails(from contents: String) -> RemoteCertificateDetails {
    var issuer = "Unavailable"
    var validFrom: Date?
    var validTo: Date?

    if let data = contents.data(using: .utf8),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        issuer = value(in: json, keys: ["issuerSummary", "issuer", "issuerName"]) ?? "Unavailable"
        validFrom = date(in: json, keys: ["validFrom", "notBefore", "validityStart"])
        validTo = date(in: json, keys: ["validTo", "notAfter", "validityEnd"])
    }

    if issuer == "Unavailable" {
        issuer = firstMatch(in: contents, pattern: "(?i)issuer\\s*[:=]\\s*([^\\n<]+)") ?? "Unavailable"
    }
    if validFrom == nil {
        validFrom = parseDate(from: firstMatch(in: contents, pattern: "(?i)(not before|valid from)\\s*[:=]\\s*([^\\n<]+)", captureGroup: 2))
    }
    if validTo == nil {
        validTo = parseDate(from: firstMatch(in: contents, pattern: "(?i)(not after|valid to|expires?)\\s*[:=]\\s*([^\\n<]+)", captureGroup: 2))
    }

    return RemoteCertificateDetails(issuerSummary: issuer, validFrom: validFrom, validTo: validTo)
}

private func value(in json: [String: Any], keys: [String]) -> String? {
    for key in keys {
        if let value = json[key] as? String, !value.isEmpty { return value }
        if let nested = json[key] as? [String: Any],
           let value = nested["name"] as? String, !value.isEmpty { return value }
    }
    if let validity = json["validity"] as? [String: Any] {
        return value(in: validity, keys: keys)
    }
    return nil
}

private func date(in json: [String: Any], keys: [String]) -> Date? {
    for key in keys {
        if let str = json[key] as? String, let parsed = parseDate(from: str) {
            return parsed
        }
    }
    if let validity = json["validity"] as? [String: Any] {
        return date(in: validity, keys: keys)
    }
    return nil
}

private func parseDate(from raw: String?) -> Date? {
    guard let raw else { return nil }
    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else { return nil }

    let iso = ISO8601DateFormatter()
    if let parsed = iso.date(from: value) { return parsed }

    let fmts = [
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        "yyyy-MM-dd",
        "MMM d yyyy",
        "MMM d, yyyy",
        "MMMM d, yyyy"
    ]
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    for format in fmts {
        formatter.dateFormat = format
        if let parsed = formatter.date(from: value) {
            return parsed
        }
    }
    return nil
}

private func firstMatch(in source: String, pattern: String, captureGroup: Int = 1) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: source, range: NSRange(source.startIndex..., in: source)),
          match.numberOfRanges > captureGroup,
          let range = Range(match.range(at: captureGroup), in: source) else {
        return nil
    }
    return String(source[range]).trimmingCharacters(in: .whitespacesAndNewlines)
}

private func certificateDate(from value: Any) -> Date? {
    if let date = value as? Date {
        return date
    }

    if let timestamp = value as? TimeInterval {
        return Date(timeIntervalSinceReferenceDate: timestamp)
    }

    if let raw = value as? String {
        return parseDate(from: raw)
    }

    return nil
}

}