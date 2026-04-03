import SwiftUI
import Foundation
import Security

private let issuerNameOID = "2.5.4.3" as CFString
private let validityNotBeforeOID = "2.5.29.16" as CFString
private let validityNotAfterOID = "2.5.29.17" as CFString
private let propertyValueKey = "value" as CFString

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
}

final class SecurityDetailsFetcher: NSObject, URLSessionDataDelegate {
    private var completion: ((SecurityDetails?) -> Void)?

    func fetch(for url: URL, completion: @escaping (SecurityDetails?) -> Void) {
        guard let host = url.host else {
            completion(nil)
            return
        }

        self.completion = completion
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

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let cert = SecTrustGetCertificateAtIndex(trust, 0)
        let commonName = cert.flatMap { SecCertificateCopySubjectSummary($0) as String? } ?? "Unavailable"

        var issuer = "Unavailable"
        var validFrom: Date?
        var validTo: Date?

        if let cert,
           let values = SecCertificateCopyValues(cert, [issuerNameOID, validityNotBeforeOID, validityNotAfterOID] as CFArray, nil) as? [CFString: Any] {
            if let issuerDict = values[issuerNameOID] as? [CFString: Any],
               let issuerValue = issuerDict[propertyValueKey] {
                issuer = String(describing: issuerValue)
            }

            if let fromDict = values[validityNotBeforeOID] as? [CFString: Any],
               let fromValue = fromDict[propertyValueKey] as? Date {
                validFrom = fromValue
            }

            if let toDict = values[validityNotAfterOID] as? [CFString: Any],
               let toValue = toDict[propertyValueKey] as? Date {
                validTo = toValue
            }
        }

        let info = SecurityDetails(
            host: challenge.protectionSpace.host,
            isSecureConnection: true,
            transport: challenge.protectionSpace.protocol ?? "HTTPS",
            certificateCommonName: commonName,
            issuerSummary: issuer,
            validFrom: validFrom,
            validTo: validTo
        )

        DispatchQueue.main.async {
            self.completion?(info)
            self.completion = nil
        }

        completionHandler(.performDefaultHandling, URLCredential(trust: trust))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            _ = error
            DispatchQueue.main.async {
                self.completion?(nil)
                self.completion = nil
            }
        }
    }
}
