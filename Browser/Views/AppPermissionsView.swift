import SwiftUI
import AVFoundation
import CoreLocation
import Photos

struct AppPermissionsView: View {
    @State private var locationStatus: CLAuthorizationStatus = .notDetermined
    @State private var cameraStatus: AVAuthorizationStatus = .notDetermined
    @State private var microphoneStatus: AVAuthorizationStatus = .notDetermined
    @State private var photoStatus: PHAuthorizationStatus = .notDetermined

    @State private var showInfoPopup = false
    @State private var pendingPermissionType: PermissionType?

    // Maintain a reference to CLLocationManager to prevent it from being deallocated
    @State private var locationManager = CLLocationManager()

    enum PermissionType {
        case location, camera, microphone, photos

        var title: String {
            switch self {
            case .location: return "Location"
            case .camera: return "Camera"
            case .microphone: return "Microphone"
            case .photos: return "Photos"
            }
        }

        var description: String {
            switch self {
            case .location: return "Allows websites to provide location-based features like local weather and maps."
            case .camera: return "Enables video conferencing and QR code scanning on supported websites."
            case .microphone: return "Allows websites to record audio for voice searches and video calls."
            case .photos: return "Allows the browser to save images from websites to your photo library."
            }
        }
    }

    var body: some View {
        List {
            Section(header: Text("Website Permissions"), footer: Text("These permissions are required for certain website features. We recommend granting them when requested by a trusted site.")) {
                permissionRow(type: .location, status: statusString(for: locationStatus))
                permissionRow(type: .camera, status: statusString(for: cameraStatus))
                permissionRow(type: .microphone, status: statusString(for: microphoneStatus))
                permissionRow(type: .photos, status: statusString(for: photoStatus))
            }
        }
        .onAppear(perform: updateStatuses)
        .alert(isPresented: $showInfoPopup) {
            Alert(
                title: Text("Requesting \(pendingPermissionType?.title ?? "Permission")"),
                message: Text(pendingPermissionType?.description ?? ""),
                primaryButton: .default(Text("Continue"), action: {
                    if let type = pendingPermissionType {
                        requestPermission(for: type)
                    }
                }),
                secondaryButton: .cancel()
            )
        }
    }

    private func permissionRow(type: PermissionType, status: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(type.title)
                    .font(.headline)
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Grant") {
                pendingPermissionType = type
                showInfoPopup = true
            }
            .buttonStyle(.bordered)
            .disabled(status == "Authorized")
        }
    }

    private func statusString(for status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: return "Authorized"
        case .denied, .restricted: return "Denied"
        default: return "Not Determined"
        }
    }

    private func statusString(for status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied, .restricted: return "Denied"
        default: return "Not Determined"
        }
    }

    private func statusString(for status: PHAuthorizationStatus) -> String {
        switch status {
        case .authorized, .limited: return "Authorized"
        case .denied, .restricted: return "Denied"
        default: return "Not Determined"
        }
    }

    private func updateStatuses() {
        locationStatus = locationManager.authorizationStatus
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        photoStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }

    private func requestPermission(for type: PermissionType) {
        switch type {
        case .location:
            locationManager.requestWhenInUseAuthorization()
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { _ in updateStatuses() }
        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { _ in updateStatuses() }
        case .photos:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in updateStatuses() }
        }
    }
}
