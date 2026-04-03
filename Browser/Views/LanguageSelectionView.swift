import SwiftUI

struct Language: Identifiable {
    let id: String
    let name: String
}

struct LanguageSelectionView: View {
    @Environment(\.dismiss) var dismiss
    var onSelect: (String) -> Void

    let languages = [
        Language(id: "en", name: "English"),
        Language(id: "es", name: "Spanish"),
        Language(id: "fr", name: "French"),
        Language(id: "de", name: "German"),
        Language(id: "it", name: "Italian"),
        Language(id: "pt", name: "Portuguese"),
        Language(id: "ru", name: "Russian"),
        Language(id: "zh-CN", name: "Chinese (Simplified)"),
        Language(id: "ja", name: "Japanese"),
        Language(id: "ko", name: "Korean"),
        Language(id: "ar", name: "Arabic"),
        Language(id: "hi", name: "Hindi")
    ].sorted { $0.name < $1.name }

    var body: some View {
        NavigationView {
            List(languages) { language in
                Button(action: {
                    onSelect(language.id)
                    dismiss()
                }) {
                    HStack {
                        Text(language.name)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Select Language")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
