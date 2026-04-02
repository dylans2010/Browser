import Foundation

struct Note: Identifiable, Codable {
    let id = UUID()
    let text: String
    let date: Date
    let sourceURL: String
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
        let newNote = Note(text: text, date: Date(), sourceURL: sourceURL)
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
