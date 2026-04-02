import SwiftUI

struct NotesView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var notesManager: NotesManager

    var body: some View {
        NavigationView {
            List {
                ForEach(notesManager.notes) { note in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(note.text)
                            .font(.body)
                        HStack {
                            Text(note.date, style: .date)
                            Spacer()
                            Text(note.sourceURL)
                                .lineLimit(1)
                                .font(.caption2)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    notesManager.notes.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("My Notes")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            })
        }
    }
}
