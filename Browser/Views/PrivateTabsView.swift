import SwiftUI

@available(iOS 16.0, *)
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
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.blue.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    if isUnlocked || storedPasscode.isEmpty {
                        if privateTabs.isEmpty {
                            emptyStateView
                        } else {
                            tabsGridView
                        }
                    } else {
                        lockView
                    }
                }
            }
            .navigationTitle("Private Browsing")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        viewModel.addTab(isEphemeral: true)
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            if #available(iOS 17.0, *) {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
                    .symbolEffect(.pulse)
            } else {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
            }
            Text("Private Tabs")
                .font(.title2.bold())
            Text("Pages you view in private tabs won't appear in your history and won't leave traces like cookies after you close them.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .foregroundStyle(.secondary)

            Button(action: {
                viewModel.addTab(isEphemeral: true)
            }) {
                Text("New Private Tab")
                    .bold()
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
    }

    private var tabsGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                ForEach(privateTabs) { tab in
                    PrivateTabCard(tab: tab, isActive: viewModel.activeTabId == tab.id) {
                        viewModel.activeTabId = tab.id
                        dismiss()
                    } onClose: {
                        viewModel.removeTab(id: tab.id)
                    }
                }
            }
            .padding()
        }
    }

    private var lockView: some View {
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

@available(iOS 16.0, *)
struct PrivateTabCard: View {
    let tab: TabItem
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.ultraThinMaterial)
                    .frame(height: 120)
                    .overlay(
                        VStack {
                            Image(systemName: "eye.slash.fill")
                                .font(.title)
                                .foregroundStyle(.secondary)
                            Text(tab.title)
                                .font(.caption)
                                .bold()
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isActive ? Color.blue : Color.clear, lineWidth: 3)
                    )

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .gray.opacity(0.6))
                        .font(.title3)
                        .padding(8)
                }
            }

            Text(tab.url?.host ?? "New Private Tab")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.leading, 5)
        }
        .onTapGesture(perform: onSelect)
    }
}
