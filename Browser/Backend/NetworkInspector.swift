import Foundation

struct NetworkLog: Identifiable, Codable {
    var id = UUID()
    let url: String
    let method: String
    let status: Int
}

class NetworkInspector: ObservableObject {
    static let shared = NetworkInspector()
    @Published var logs: [NetworkLog] = []

    func logRequest(url: String, method: String, status: Int) {
        DispatchQueue.main.async {
            self.logs.append(NetworkLog(url: url, method: method, status: status))
        }
    }

    func clear() {
        logs.removeAll()
    }
}
