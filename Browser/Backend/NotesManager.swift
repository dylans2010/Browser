import Foundation

struct Note: Identifiable, Codable {
    var id = UUID()
    let text: String
    let date: Date
    let sourceURL: String
    var title: String = ""
    var content: String = "" // Markdown content
    var dateCreated: Date = Date()
}

class NotesManager: ObservableObject {
    @Published var notes: [Note] = [] {
        didSet {
            saveNotes()
        }
    }

    private let notesKey = "saved_notes"

    init() {
        loadNotes()
    }

    func addNote(text: String, sourceURL: String) {
        let newNote = Note(text: text, date: Date(), sourceURL: sourceURL, title: "Quick Note", content: text)
        notes.append(newNote)
    }

    func addNote(title: String, content: String, sourceURL: String) {
        let newNote = Note(text: content, date: Date(), sourceURL: sourceURL, title: title, content: content)
        notes.append(newNote)
    }

    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
        }
    }

    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
    }
}
