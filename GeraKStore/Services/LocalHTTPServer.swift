import Foundation
import Network

public final class LocalHTTPServer {
    public static let shared = LocalHTTPServer()

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.gerakstore.localserver", qos: .userInitiated)
    public private(set) var isRunning: Bool = false

    private init() {}

    public func start(port: UInt16 = StoreConfig.localServerPort) {
        guard !isRunning else { return }

        do {
            let parameters = NWParameters.tcp
            guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }
            listener = try NWListener(using: parameters, on: nwPort)

            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }

            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.isRunning = true
                    print("Локальный OTA-сервер запущен на порту \(port)")
                case .failed(let error):
                    print("Ошибка локального сервера: \(error.localizedDescription)")
                    self?.stop()
                default:
                    break
                }
            }

            listener?.start(queue: queue)
        } catch {
            print("Не удалось инициализировать NWListener: \(error.localizedDescription)")
        }
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, error in
            guard let self = self, let data = data, error == nil else {
                connection.cancel()
                return
            }

            let requestString = String(decoding: data, as: UTF8.self)
            self.routeRequest(requestString, connection: connection)
        }
    }

    private func routeRequest(_ request: String, connection: NWConnection) {
        let lines = request.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            connection.cancel()
            return
        }

        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            connection.cancel()
            return
        }

        let path = parts[1]

        if path.contains("manifest.plist") {
            let manifestPath = PathConfig.getDirectory(PathConfig.tempCacheFolder).appendingPathComponent("manifest.plist")
            serveFile(at: manifestPath, contentType: "application/xml", connection: connection)
        } else if path.contains("/download/") {
            let fileName = path.replacingOccurrences(of: "/download/", with: "")
            let ipaPath = PathConfig.getDirectory(PathConfig.ipaDownloadsFolder).appendingPathComponent(fileName)
            serveFile(at: ipaPath, contentType: "application/octet-stream", connection: connection)
        } else {
            sendResponse(status: "404 Not Found", body: Data("Not Found".utf8), contentType: "text/plain", connection: connection)
        }
    }

    private func serveFile(at url: URL, contentType: String, connection: NWConnection) {
        guard let data = try? Data(contentsOf: url) else {
            sendResponse(status: "404 Not Found", body: Data("File not found".utf8), contentType: "text/plain", connection: connection)
            return
        }
        sendResponse(status: "200 OK", body: data, contentType: contentType, connection: connection)
    }

    private func sendResponse(status: String, body: Data, contentType: String, connection: NWConnection) {
        let headers = """
        HTTP/1.1 \(status)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.count)\r
        Connection: close\r
        \r\n
        """
        guard let headerData = headers.data(using: .utf8) else {
            connection.cancel()
            return
        }

        var responseData = headerData
        responseData.append(body)

        connection.send(content: responseData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}
