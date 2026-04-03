import SwiftUI

struct NotesDetailView: View {
    @EnvironmentObject var notesManager: NotesManager
    @Environment(\.dismiss) var dismiss

    @State var note: Note
    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var editedContent = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isEditing {
                    TextField("Title", text: $editedTitle)
                        .font(.title.bold())
                        .textFieldStyle(.roundedBorder)

                    TextEditor(text: $editedContent)
                        .font(.body)
                        .frame(minHeight: 300)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                } else {
                    Text(note.title)
                        .font(.title.bold())

                    Divider()

                    Text(LocalizedStringKey(note.content))
                        .font(.body)
                        .textSelection(.enabled)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Label(note.sourceURL, systemImage: "link")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Label(note.dateCreated.formatted(), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Note Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        startEditing()
                    }
                    isEditing.toggle()
                }
            }
        }
    }

    private func startEditing() {
        editedTitle = note.title
        editedContent = note.content
    }

    private func saveChanges() {
        if let index = notesManager.notes.firstIndex(where: { $0.id == note.id }) {
            notesManager.notes[index].title = editedTitle
            notesManager.notes[index].content = editedContent
            note = notesManager.notes[index]
        }
    }
}
