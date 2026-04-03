import SwiftUI

struct AIResultView: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let content: String
    let isLoading: Bool

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    if isLoading {
                        ProgressView("Analyzing...")
                            .padding()
                    } else {
                        ScrollView {
                            Text(content)
                                .padding()
                                .font(.body)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
