import Foundation

class ElementHiderManager: ObservableObject {
    @Published var hiddenSelectors: [String: [String]] = [:] // Domain: Selectors

    private let storageKey = "hidden_elements"

    init() {
        loadData()
    }

    func hideElement(selector: String, for domain: String) {
        var selectors = hiddenSelectors[domain] ?? []
        if !selectors.contains(selector) {
            selectors.append(selector)
            hiddenSelectors[domain] = selectors
            saveData()
        }
    }

    func clearSelectors(for domain: String) {
        hiddenSelectors.removeValue(forKey: domain)
        saveData()
    }

    func getInjectionScript(for domain: String) -> String {
        guard let selectors = hiddenSelectors[domain], !selectors.isEmpty else { return "" }
        let selectorsString = selectors.joined(separator: "', '")
        return """
        (function() {
            const selectors = ['\(selectorsString)'];
            selectors.forEach(selector => {
                document.querySelectorAll(selector).forEach(el => {
                    el.style.display = 'none';
                });
            });
        })();
        """
    }

    func getSelectionScript() -> String {
        return """
        (function() {
            if (window.__elementHiderActive) { return; }
            window.__elementHiderActive = true;

            const style = document.createElement('style');
            style.id = 'element-hider-overlay';
            style.innerHTML = `
                *:hover { outline: 2px solid #ff3b30 !important; cursor: crosshair !important; }
                html, body { cursor: crosshair !important; }
            `;
            document.head.appendChild(style);

            const clickHandler = function(e) {
                e.preventDefault();
                e.stopPropagation();
                e.stopImmediatePropagation();
                const selector = getUniqueSelector(e.target);
                e.target.style.display = 'none';
                window.webkit.messageHandlers.elementHider.postMessage(selector);
            };

            const getUniqueSelector = function(el) {
                if (el.id) return '#' + el.id;
                if (el.className) {
                    const classes = Array.from(el.classList).join('.');
                    if (classes) return el.tagName.toLowerCase() + '.' + classes;
                }
                return el.tagName.toLowerCase();
            };

            const blockNavigation = function(e) {
                e.preventDefault();
                e.stopPropagation();
                e.stopImmediatePropagation();
            };

            const keyHandler = function(e) {
                if (e.key === 'Escape') {
                    cleanup();
                }
            };

            const cleanup = function() {
                window.__elementHiderActive = false;
                const existingStyle = document.getElementById('element-hider-overlay');
                if (existingStyle) {
                    existingStyle.remove();
                }
                document.removeEventListener('click', clickHandler, true);
                document.removeEventListener('auxclick', blockNavigation, true);
                document.removeEventListener('submit', blockNavigation, true);
                document.removeEventListener('keydown', keyHandler, true);
            };

            window.__elementHiderCleanup = cleanup;
            document.addEventListener('click', clickHandler, true);
            document.addEventListener('auxclick', blockNavigation, true);
            document.addEventListener('submit', blockNavigation, true);
            document.addEventListener('keydown', keyHandler, true);
        })();
        """
    }

    private func saveData() {
        UserDefaults.standard.set(hiddenSelectors, forKey: storageKey)
    }

    private func loadData() {
        if let data = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: [String]] {
            hiddenSelectors = data
        }
    }
}
