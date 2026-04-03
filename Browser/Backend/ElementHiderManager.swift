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
            let lastEl;
            const style = document.createElement('style');
            style.id = 'element-hider-overlay';
            style.innerHTML = '*:hover { outline: 2px solid red !important; }';
            document.head.appendChild(style);

            const clickHandler = (e) => {
                e.preventDefault();
                e.stopPropagation();
                const selector = getUniqueSelector(e.target);
                window.webkit.messageHandlers.elementHider.postMessage(selector);
                cleanup();
            };

            const getUniqueSelector = (el) => {
                if (el.id) return '#' + el.id;
                if (el.className) {
                    const classes = Array.from(el.classList).join('.');
                    if (classes) return el.tagName.toLowerCase() + '.' + classes;
                }
                return el.tagName.toLowerCase();
            };

            const cleanup = () => {
                document.head.removeChild(style);
                document.removeEventListener('click', clickHandler, true);
            };

            document.addEventListener('click', clickHandler, true);
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
