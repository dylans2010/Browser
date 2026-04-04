import SwiftUI

struct PageInfoView: View {
    let info: PageInfo
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("General") {
                    HStack {
                        Text("Title")
                        Spacer()
                        Text(info.title).foregroundColor(.secondary)
                    }
                    HStack {
                        Text("URL")
                        Spacer()
                        Text(info.url).foregroundColor(.secondary).lineLimit(1).truncationMode(.tail)
                    }
                }

                Section("Security") {
                    HStack {
                        Image(systemName: info.isSecure ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(info.isSecure ? .green : .red)
                        Text(info.isSecure ? "Secure Connection (HTTPS)" : "Insecure Connection (HTTP)")
                    }
                }

                Section("Privacy") {
                    HStack {
                        Text("Cookies Found")
                        Spacer()
                        Text("\(info.cookieCount)")
                    }
                }
            }
            .navigationTitle("Page Info")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
