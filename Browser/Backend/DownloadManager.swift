import Foundation
import Combine
#if os(iOS)
import UIKit
#endif

enum DownloadStatus: String, Codable {
    case downloading
    case completed
    case failed
}

struct DownloadItem: Identifiable, Codable {
    var id = UUID()
    let fileName: String
    var progress: Double
    var status: DownloadStatus
    var localURL: URL?
}

class DownloadManager: ObservableObject {
    @Published var downloads: [DownloadItem] = []
    @Published var showDownloadsUI: Bool = false

    private var downloadTasks: [UUID: URLSessionDownloadTask] = [:]

    func startDownload(url: URL) {
        let fileName = url.lastPathComponent.isEmpty ? "download" : url.lastPathComponent
        let item = DownloadItem(fileName: fileName, progress: 0.0, status: .downloading)
        downloads.append(item)
        showDownloadsUI = true

        let session = URLSession(configuration: .default, delegate: DownloadDelegate(manager: self, itemId: item.id), delegateQueue: .main)
        let task = session.downloadTask(with: url)
        downloadTasks[item.id] = task
        task.resume()
    }

    func openFile(item: DownloadItem) {
        guard let url = item.localURL else { return }
        #if os(iOS)
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }

    func deleteFile(item: DownloadItem) {
        if let url = item.localURL {
            try? FileManager.default.removeItem(at: url)
        }
        downloads.removeAll { $0.id == item.id }
    }

    func clearAll() {
        for item in downloads {
            if let url = item.localURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
        downloads.removeAll()
    }

    fileprivate func updateProgress(id: UUID, progress: Double) {
        if let index = downloads.firstIndex(where: { $0.id == id }) {
            downloads[index].progress = progress
        }
    }

    fileprivate func completeDownload(id: UUID, localURL: URL) {
        if let index = downloads.firstIndex(where: { $0.id == id }) {
            let fileName = downloads[index].fileName
            let downloadsFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
            let destinationURL = downloadsFolder.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: destinationURL)
            try? FileManager.default.moveItem(at: localURL, to: destinationURL)

            downloads[index].status = .completed
            downloads[index].progress = 1.0
            downloads[index].localURL = destinationURL
        }
    }

    fileprivate func failDownload(id: UUID) {
        if let index = downloads.firstIndex(where: { $0.id == id }) {
            downloads[index].status = .failed
        }
    }
}

class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let manager: DownloadManager
    let itemId: UUID

    init(manager: DownloadManager, itemId: UUID) {
        self.manager = manager
        self.itemId = itemId
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        manager.completeDownload(id: itemId, localURL: location)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        manager.updateProgress(id: itemId, progress: progress)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            manager.failDownload(id: itemId)
        }
    }
}
