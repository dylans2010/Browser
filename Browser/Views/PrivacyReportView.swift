import SwiftUI

struct PrivacyReportView: View {
    let report: PrivacyReport
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Overview")) {
                    HStack {
                        Text("Trackers Blocked")
                        Spacer()
                        Text("\(report.trackersFound)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }

                Section(header: Text("Blocked Trackers")) {
                    ForEach(report.blockedTrackers, id: \.self) { tracker in
                        HStack {
                            Image(systemName: "shield.fill")
                                .foregroundColor(.green)
                            Text(tracker)
                        }
                    }
                }
            }
            .navigationTitle("Privacy Report")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
