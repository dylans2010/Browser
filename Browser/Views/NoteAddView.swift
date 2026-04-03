import SwiftUI

struct NoteAddView: View {
    @EnvironmentObject var notesManager: NotesManager
    @Environment(\.dismiss) var dismiss

    @State private var title: String = ""
    @State private var content: String = ""
    var sourceURL: String

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Note Title", text: $title)
                }
                Section(header: Text("Content (Markdown supported)")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
                Section(header: Text("Source URL")) {
                    Text(sourceURL)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        notesManager.addNote(title: title, content: content, sourceURL: sourceURL)
                        dismiss()
                    }
                    .disabled(content.isEmpty)
                }
            }
        }
    }
}
