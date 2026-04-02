import SwiftUI

struct PrivateTabsView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @AppStorage("privatePasscode") var storedPasscode: String = ""
    @Environment(\.dismiss) var dismiss

    @State private var inputPasscode: String = ""
    @State private var isUnlocked: Bool = false
    @State private var showError: Bool = false

    var privateTabs: [TabItem] {
        viewModel.tabs.filter { $0.isEphemeral }
    }

    var body: some View {
        NavigationView {
            VStack {
                if isUnlocked || storedPasscode.isEmpty {
                    if privateTabs.isEmpty {
                        VStack {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 60))
                                .padding()
                            Text("No Private Tabs")
                                .font(.headline)
                        }
                        .foregroundColor(.secondary)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                                ForEach(privateTabs) { tab in
                                    VStack {
                                        ZStack(alignment: .topTrailing) {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.black.opacity(0.8))
                                                .frame(height: 120)
                                                .overlay(
                                                    Text(tab.title)
                                                        .font(.caption)
                                                        .foregroundColor(.white)
                                                        .padding(8)
                                                )

                                            Button(action: {
                                                viewModel.removeTab(id: tab.id)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.gray)
                                                    .padding(4)
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        Text(tab.title)
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                    .onTapGesture {
                                        viewModel.activeTabId = tab.id
                                        dismiss()
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 48))
                        Text("Private Browsing Locked")
                            .font(.title2)

                        SecureField("Enter Passcode", text: $inputPasscode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                            .multilineTextAlignment(.center)

                        Button("Unlock") {
                            if inputPasscode == storedPasscode {
                                isUnlocked = true
                            } else {
                                showError = true
                                inputPasscode = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        if showError {
                            Text("Incorrect Passcode")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Private Tabs")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
