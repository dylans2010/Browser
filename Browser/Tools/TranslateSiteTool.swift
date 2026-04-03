import Foundation
import WebKit

struct TranslateSiteTool {
    static func execute(in webView: WKWebView, targetLanguage: String = "en") {
        // We can use the Google Translate Element or a simple JS snippet to translate the page.
        // This script adds the Google Translate widget and then triggers it.
        // While Google is deprecating the free widget, it still works on many sites or we can use a more direct approach.

        let js = """
        (function() {
            if (window.google && window.google.translate) {
                // If already loaded, try to trigger it
                return;
            }
            var script = document.createElement('script');
            script.type = 'text/javascript';
            script.src = '//translate.google.com/translate_a/element.js?cb=googleTranslateElementInit';
            document.body.appendChild(script);

            window.googleTranslateElementInit = function() {
                new google.translate.TranslateElement({
                    pageLanguage: 'auto',
                    includedLanguages: '\(targetLanguage)',
                    layout: google.translate.TranslateElement.InlineLayout.SIMPLE,
                    autoDisplay: false
                }, 'google_translate_element');
            };

            var div = document.createElement('div');
            div.id = 'google_translate_element';
            div.style.display = 'none';
            document.body.appendChild(div);
        })();
        """
        webView.evaluateJavaScript(js)
    }
}
