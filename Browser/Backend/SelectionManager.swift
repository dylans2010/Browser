import Foundation
import WebKit

@available(iOS 16.0, *)
class SelectionManager: NSObject, ObservableObject, WKScriptMessageHandler {
    static let shared = SelectionManager()

    @Published var selectedText: String = ""
    @Published var selectedHTML: String = ""
    @Published var isSelectionModeEnabled: Bool = false

    private weak var webView: WKWebView?

    func enableSelectionMode(in webView: WKWebView) {
        self.webView = webView
        self.isSelectionModeEnabled = true

        let script = """
        (function() {
            if (window.__selectionHandlerActive) return;
            window.__selectionHandlerActive = true;

            // Add a style for highlighting
            const style = document.createElement('style');
            style.id = 'browser-assistant-selection-style';
            style.innerHTML = `
                .browser-assistant-highlight {
                    outline: 2px solid #007AFF !important;
                    background-color: rgba(0, 122, 255, 0.1) !important;
                    cursor: crosshair !important;
                    transition: outline 0.2s ease, background-color 0.2s ease;
                }
                html, body { cursor: crosshair !important; }
            `;
            document.head.appendChild(style);

            window.__selectionHandler = function(e) {
                if (!window.__selectionModeEnabled) return;
                e.preventDefault();
                e.stopPropagation();
                e.stopImmediatePropagation();

                const element = e.target;
                const text = element.innerText || element.textContent;
                const html = element.outerHTML;

                window.webkit.messageHandlers.selectionHandler.postMessage({
                    text: text,
                    html: html
                });
            };

            window.__highlightHandler = function(e) {
                if (!window.__selectionModeEnabled) return;
                const element = e.target;
                element.classList.add('browser-assistant-highlight');
            };

            window.__unhighlightHandler = function(e) {
                const element = e.target;
                element.classList.remove('browser-assistant-highlight');
            };

            const blockNavigation = function(e) {
                if (window.__selectionModeEnabled) {
                    e.preventDefault();
                    e.stopPropagation();
                    e.stopImmediatePropagation();
                }
            };

            document.addEventListener('click', window.__selectionHandler, true);
            document.addEventListener('mouseover', window.__highlightHandler, true);
            document.addEventListener('mouseout', window.__unhighlightHandler, true);
            document.addEventListener('auxclick', blockNavigation, true);
            document.addEventListener('submit', blockNavigation, true);

            window.__selectionModeEnabled = true;
        })();
        """

        // Ensure we don't add the handler twice
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "selectionHandler")
        webView.configuration.userContentController.add(self, name: "selectionHandler")
        webView.evaluateJavaScript(script)
    }

    func disableSelectionMode() {
        self.isSelectionModeEnabled = false
        let script = """
        (function() {
            window.__selectionModeEnabled = false;
            window.__selectionHandlerActive = false;
            const style = document.getElementById('browser-assistant-selection-style');
            if (style) style.remove();

            document.querySelectorAll('.browser-assistant-highlight').forEach(el => {
                el.classList.remove('browser-assistant-highlight');
            });

            document.removeEventListener('click', window.__selectionHandler, true);
            document.removeEventListener('mouseover', window.__highlightHandler, true);
            document.removeEventListener('mouseout', window.__unhighlightHandler, true);
        })();
        """
        webView?.evaluateJavaScript(script)
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "selectionHandler")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "selectionHandler", let body = message.body as? [String: String] {
            DispatchQueue.main.async {
                self.selectedText = (body["text"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                self.selectedHTML = body["html"] ?? ""
                // Once selection is made, we stop selection mode
                self.disableSelectionMode()
            }
        }
    }
}
