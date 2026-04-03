import SwiftUI
import WebKit

struct AddressBarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @FocusState.Binding var isFocused: Bool

    var onCommit: () -> Void
    var menuItems: AnyView?

    var body: some View {
        HStack(spacing: 12) {
            // Leading: Lock icon (HTTPS)
            if !viewModel.urlString.isEmpty {
                Image(systemName: URLFormatter.isSecure(viewModel.urlString) ? "lock.fill" : "lock.open")
                    .font(.system(size: 11))
                    .foregroundColor(URLFormatter.isSecure(viewModel.urlString) ? .green : .orange)
            }

            // Center: TextField
            ZStack {
                if !isFocused {
                    Text(displayURLText)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity)
                }

                TextField("Search or enter URL", text: $viewModel.urlString)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14))
                    .focused($isFocused)
                    .submitLabel(.go)
                    .opacity(isFocused ? 1 : 0)
                    .onSubmit {
                        onCommit()
                    }
            }

            // Trailing: Reload / Stop button
            if !viewModel.urlString.isEmpty {
                Button(action: {
                    if viewModel.isLoading {
                        viewModel.stopLoading()
                    } else {
                        viewModel.reload()
                    }
                }) {
                    Image(systemName: viewModel.isLoading ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            // 3-dot menu button
            if let menu = menuItems {
                Menu {
                    menu
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(6)
                        .background(Circle().fill(Color.primary.opacity(0.1)))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }

    private var displayURLText: String {
        if viewModel.urlString.isEmpty {
            return "Search or enter URL"
        }
        return URLFormatter.formatted(viewModel.urlString)
    }
}
