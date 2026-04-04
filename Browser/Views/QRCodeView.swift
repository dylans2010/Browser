import SwiftUI

struct QRCodeView: View {
    let urlString: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if let qrImage = GenerateQRCodeTool.generate(from: urlString) {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }

                Text(urlString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    if let image = GenerateQRCodeTool.generate(from: urlString) {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    }
                    dismiss()
                }) {
                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationTitle("QR Code")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
