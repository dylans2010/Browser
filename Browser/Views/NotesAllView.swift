import SwiftUI

struct NotesAllView: View {
    @EnvironmentObject var notesManager: NotesManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(notesManager.notes) { note in
                    NavigationLink(destination: NotesDetailView(note: note)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(note.title)
                                .font(.headline)

                            // Render Markdown content natively (requires iOS 15+, using Text(LocalizedStringKey))
                            Text(LocalizedStringKey(note.content))
                                .font(.subheadline)
                                .lineLimit(3)
                                .padding(.top, 4)

                            Text(note.sourceURL)
                                .font(.caption2)
                                .foregroundColor(.blue)

                            Text(note.dateCreated, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indexSet in
                    notesManager.notes.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("All Notes")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
