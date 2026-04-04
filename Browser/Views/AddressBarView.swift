import SwiftUI
import WebKit
import UIKit

@available(iOS 16.0, *)
struct AddressBarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @FocusState.Binding var isFocused: Bool

    var onCommit: () -> Void
    var onBrowserAssistantTap: () -> Void = {}
    var menuItems: AnyView? = nil

    @AppStorage("addressBarAlignment") var alignment: String = "Center"
    @AppStorage("addressBarSize") var barSize: Double = 1.0 // Scale factor
    @AppStorage("showSiteIcon") var showSiteIcon: Bool = true
    @AppStorage("showReadTime") var showReadTime: Bool = true
    @AppStorage("addressBarGestures") var enableGestures: Bool = true
    @AppStorage("showBrowserAssistant") var showBrowserAssistant: Bool = true
    @AppStorage("alwaysShowAddressBar") var alwaysShowAddressBar: Bool = true

    // Customization
    @AppStorage("addressBarButtons") var selectedButtonsJSON: String = "[\"back\", \"forward\", \"reload\", \"browserAssistant\", \"ellipsis\"]"

    // Fine tuning
    @AppStorage("addressBarCornerRadius") var barCornerRadius: Double = 25.0
    @AppStorage("addressBarShadowRadius") var barShadowRadius: Double = 10.0
    @AppStorage("addressBarOpacity") var barOpacity: Double = 1.0
    @AppStorage("addressBarBlur") var barBlurIntensity: Double = 1.0

    @EnvironmentObject var toolbarManager: ToolbarManager

    @State private var isReloadAnimating = false

    private var selectedButtons: [String] {
        if let data = selectedButtonsJSON.data(using: .utf8),
           let buttons = try? JSONDecoder().decode([String].self, from: data) {
            return buttons
        }
        return ["back", "forward", "reload", "browserAssistant", "ellipsis"]
    }

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 10) {
                // Leading Buttons (back, forward)
                if !isFocused {
                    HStack(spacing: 12) {
                        if selectedButtons.contains("back") {
                            Button(action: { viewModel.goBack() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14 * barSize, weight: .bold))
                                    .foregroundColor(viewModel.canGoBack ? .primary : .secondary.opacity(0.3))
                            }
                            .disabled(!viewModel.canGoBack)
                        }

                        if selectedButtons.contains("forward") {
                            Button(action: { viewModel.goForward() }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14 * barSize, weight: .bold))
                                    .foregroundColor(viewModel.canGoForward ? .primary : .secondary.opacity(0.3))
                            }
                            .disabled(!viewModel.canGoForward)
                        }
                    }
                    .padding(.leading, 8)
                }

                // Site Icon / Lock
                if showSiteIcon {
                    if let host = viewModel.activeTab?.url?.host {
                        AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?sz=64&domain=\(host)")) { image in
                            image.resizable()
                        } placeholder: {
                            Image(systemName: "globe")
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 18 * barSize, height: 18 * barSize)
                        .cornerRadius(4)
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 14 * barSize))
                            .foregroundColor(.secondary)
                    }
                }

                // Center: TextField and Info
                VStack(alignment: textAlignment, spacing: 0) {
                    ZStack {
                        if !isFocused {
                            Text(displayURLText)
                                .font(.system(size: 14 * barSize, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: textAlignment == .center ? .center : (textAlignment == .leading ? .leading : .trailing))
                                .allowsHitTesting(false)
                        }

                        TextField("Search or enter URL", text: $viewModel.urlString)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(textFieldAlignment)
                            .font(.system(size: 14 * barSize))
                            .focused($isFocused)
                            .submitLabel(.go)
                            .opacity(isFocused ? 1 : 0)
                            .onSubmit {
                                onCommit()
                            }
                    }

                    if !isFocused && showReadTime, let readTime = viewModel.estimatedReadTime {
                        Text("\(readTime) min read")
                            .font(.system(size: 10 * barSize))
                            .foregroundColor(.secondary)
                            .transition(.opacity)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused = true
                    selectAllAddressText()
                }

                // Trailing Buttons
                if !isFocused {
                    HStack(spacing: 12) {
                        if selectedButtons.contains("browserAssistant") {
                            Button(action: { onBrowserAssistantTap() }) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14 * barSize, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }

                        if selectedButtons.contains("reload") {
                            Button(action: {
                                if viewModel.isLoading {
                                    viewModel.stopLoading()
                                } else {
                                    viewModel.reload()
                                }
                            }) {
                                Image(systemName: viewModel.isLoading ? "xmark" : "arrow.clockwise")
                                    .font(.system(size: 14 * barSize, weight: .bold))
                                    .foregroundColor(.primary)
                                    .rotationEffect(.degrees(isReloadAnimating ? 360 : 0))
                                    .animation(
                                        viewModel.isLoading
                                        ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                                        : .default,
                                        value: isReloadAnimating
                                    )
                            }
                        }

                        if selectedButtons.contains("ellipsis"), let menu = menuItems {
                            Menu {
                                menu
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 14 * barSize, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.trailing, 8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8 * barSize)
            .background(
                RoundedRectangle(cornerRadius: barCornerRadius)
                    .fill(.ultraThinMaterial.opacity(barBlurIntensity))
                    .opacity(barOpacity)
                    .shadow(color: Color.black.opacity(0.1), radius: barShadowRadius, x: 0, y: 5)
            )
            .scaleEffect(barSize)
        }
        .padding(.horizontal)
        .gesture(
            enableGestures ? DragGesture().onEnded { value in
                if value.translation.width < -50 {
                    viewModel.goForward()
                } else if value.translation.width > 50 {
                    viewModel.goBack()
                }
            } : nil
        )
        .onChange(of: viewModel.isLoading) { isLoading in
            isReloadAnimating = isLoading
        }
    }

    private var textAlignment: HorizontalAlignment {
        switch alignment {
        case "Left": return .leading
        case "Right": return .trailing
        default: return .center
        }
    }

    private var textFieldAlignment: TextAlignment {
        switch alignment {
        case "Left": return .leading
        case "Right": return .trailing
        default: return .center
        }
    }

    private var displayURLText: String {
        if viewModel.urlString.isEmpty {
            return "Search or enter URL"
        }
        return URLFormatter.formatted(viewModel.urlString)
    }
}

private extension AddressBarView {
    func selectAllAddressText() {
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
        }
    }
}
