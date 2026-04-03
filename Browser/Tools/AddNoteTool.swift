import Foundation
import WebKit

struct AddNoteTool {
    static func execute(url: String, notesManager: NotesManager, onComplete: () -> Void) {
        notesManager.addNote(text: "New note for \(url)", sourceURL: url)
        onComplete()
    }
}
