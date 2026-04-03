import SwiftUI
import WebKit
import UIKit

@available(iOS 16.0, *)
struct AddressBarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @FocusState.Binding var isFocused: Bool

    var onCommit: () -> Void
    var onSecurityTap: () -> Void
    var onShowToolsMenu: () -> Void
    var onShowShare: () -> Void
    var onShowBookmarks: () -> Void
    var onShowTabs: () -> Void

    @State private var editingText: String = ""

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                HStack(spacing: 10) {
                    Button(action: onSecurityTap) {
                        Image(systemName: URLFormatter.isSecure(viewModel.urlString) ? "lock.fill" : "lock.open")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(URLFormatter.isSecure(viewModel.urlString) ? .green : .orange)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.urlString.isEmpty)

                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    ZStack(alignment: .leading) {
                        if !isFocused {
                            Text(displayURLText)
                                .font(.system(size: 14))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        SelectableURLTextField(
                            text: isFocused ? $editingText : .constant(displayURLText),
                            isEditing: isFocused,
                            onSubmit: {
                                viewModel.urlString = editingText
                                onCommit()
                            }
                        )
                        .focused($isFocused)
                        .opacity(isFocused ? 1 : 0.01)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !isFocused {
                            editingText = viewModel.urlString
                            isFocused = true
                        }
                    }
                    .onChange(of: isFocused) { focused in
                        withAnimation(.easeInOut(duration: 0.18)) {
                            if focused {
                                editingText = viewModel.urlString
                            } else {
                                editingText = ""
                            }
                        }
                    }

                    Button(action: {
                        if viewModel.isLoading {
                            viewModel.stopLoading()
                        } else {
                            viewModel.reload()
                        }
                    }) {
                        Image(systemName: viewModel.isLoading ? "xmark" : "arrow.clockwise")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: onShowToolsMenu) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.secondarySystemBackground).opacity(0.7))
                )
                .scaleEffect(isFocused ? 1.01 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.85), value: isFocused)

                if viewModel.isLoading {
                    Rectangle()
                        .fill(.blue.gradient)
                        .frame(height: 2)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
                }
            }

            HStack {
                navButton(icon: "chevron.left", disabled: !viewModel.canGoBack) {
                    viewModel.goBack()
                }
                Spacer()
                navButton(icon: "chevron.right", disabled: !viewModel.canGoForward) {
                    viewModel.goForward()
                }
                Spacer()
                navButton(icon: "square.and.arrow.up", disabled: viewModel.urlString.isEmpty, action: onShowShare)
                Spacer()
                navButton(icon: "book", action: onShowBookmarks)
                Spacer()
                navButton(icon: "square.on.square", action: onShowTabs)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 7)
        )
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
        .onChange(of: viewModel.urlString) { updated in
            if !isFocused {
                editingText = updated
            }
        }
    }

    private func navButton(icon: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .opacity(disabled ? 0.35 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var displayURLText: String {
        if viewModel.urlString.isEmpty {
            return "Search or enter website"
        }
        return URLFormatter.formatted(viewModel.urlString)
    }
}

private struct SelectableURLTextField: UIViewRepresentable {
    @Binding var text: String
    var isEditing: Bool
    var onSubmit: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.placeholder = "Search or enter website"
        textField.borderStyle = .none
        textField.returnKeyType = .go
        textField.clearButtonMode = .never
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .URL
        textField.textAlignment = .left
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        if isEditing {
            if !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
                DispatchQueue.main.async {
                    uiView.selectAll(nil)
                }
            }
        } else if uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SelectableURLTextField

        init(_ parent: SelectableURLTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.text = textField.text ?? ""
            parent.onSubmit()
            return false
        }
    }
}
