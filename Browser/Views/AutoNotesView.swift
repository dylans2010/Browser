import SwiftUI

@available(iOS 16.0, *)
struct AutoNotesView: View {
    @EnvironmentObject var notesManager: NotesManager
    @Environment(\.dismiss) var dismiss

    @StateObject var autoNotesManager = AutoNotesManager.shared
    @EnvironmentObject var browserViewModel: BrowserViewModel

    @State private var editedContent: String = ""
    @State private var editedTitle: String = "Auto Note"
    @State private var isEditing = false

    var sourceURL: String

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if autoNotesManager.isGenerating {
                    ProgressView("Analyzing content & patterns...")
                        .padding()
                } else if let note = autoNotesManager.lastGeneratedNote {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            if isEditing {
                                TextField("Note Title", text: $editedTitle)
                                    .font(.title3.bold())
                                    .textFieldStyle(.roundedBorder)

                                TextEditor(text: $editedContent)
                                    .frame(minHeight: 200)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                            } else {
                                Text(editedTitle)
                                    .font(.title3.bold())

                                Text(editedContent)
                                    .font(.body)
                                    .padding(.top, 4)
                            }
                        }
                        .padding()
                        .onAppear {
                            if editedContent.isEmpty {
                                parseNote(note)
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Button(isEditing ? "Done Editing" : "Edit Note") {
                            isEditing.toggle()
                        }
                        .buttonStyle(.bordered)

                        Button("Save to Notes") {
                            saveNote()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "note.text.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No note generated for this page yet.")
                            .font(.headline)
                        Button("Generate Note Now") {
                            Task {
                                let content = await browserViewModel.extractPageContent()
                                await autoNotesManager.generateNote(for: URL(string: sourceURL), content: content)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
            .navigationTitle("Auto Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func parseNote(_ rawNote: String) {
        let lines = rawNote.components(separatedBy: .newlines)
        if let firstLine = lines.first?.trimmingCharacters(in: CharacterSet(charactersIn: "# ")), !firstLine.isEmpty {
            editedTitle = firstLine
            editedContent = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            editedContent = rawNote
        }
    }

    private func saveNote() {
        notesManager.addNote(title: editedTitle, content: editedContent, sourceURL: sourceURL)
        if let host = URL(string: sourceURL)?.host {
            AutoNotesLearning.shared.learnFromNote(content: editedContent, domain: host)
        }
    }
}
