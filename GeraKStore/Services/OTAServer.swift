import Foundation
import Network

public final class OTAServer {
    public static let shared = OTAServer()

    private var listener: NWListener?
    private let port: UInt16 = 8080
    private var isRunning: Bool = false

    private init() {}

    /// Запуск локального HTTP сервера на порту 8080
    public func start() {
        guard !isRunning else { return }

        do {
            let parameters = NWParameters.tcp
            self.listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            
            self.listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    self.isRunning = true
                    print("OTA HTTP Сервер запущен на порту \(self.port)")
                case .failed(let error):
                    print("Ошибка OTA Сервера: \(error.localizedDescription)")
                    self.stop()
                default:
                    break
                }
            }

            self.listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }

            self.listener?.start(queue: .global(qos: .userInitiated))
        } catch {
            print("Не удалось инициализировать NWListener: \(error.localizedDescription)")
        }
    }

    /// Остановка сервера после завершения установки
    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
        print("OTA HTTP Сервер остановлен")
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        receiveRequest(connection)
    }

    private func receiveRequest(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, isComplete, error in
            guard let self = self, let data = data, !data.isEmpty else {
                connection.cancel()
                return
            }

            if let requestString = String(data: data, encoding: .utf8) {
                self.processHttpRequest(request: requestString, connection: connection)
            } else {
                connection.cancel()
            }
        }
    }

    private func processHttpRequest(request: String, connection: NWConnection) {
        let lines = request.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            connection.cancel()
            return
        }

        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2, parts[0] == "GET" else {
            connection.cancel()
            return
        }

        let rawPath = parts[1]
        let cleanPath = rawPath.split(separator: "?").first.map(String.init) ?? rawPath

        if cleanPath == "/manifest.plist" {
            serveManifest(connection: connection)
        } else if cleanPath.hasSuffix(".ipa") {
            let fileName = (cleanPath as NSString).lastPathComponent
            serveIPA(fileName: fileName, connection: connection)
        } else {
            sendNotFound(connection: connection)
        }
    }

    private func serveManifest(connection: NWConnection) {
        let manifestUrl = PathConfig.getDirectory(PathConfig.signedAppsFolder).appendingPathComponent("manifest.plist")
        guard let data = try? Data(contentsOf: manifestUrl) else {
            sendNotFound(connection: connection)
            return
        }

        let headers = "HTTP/1.1 200 OK\r\n" +
                      "Content-Type: text/xml\r\n" +
                      "Content-Length: \(data.count)\r\n" +
                      "Connection: close\r\n\r\n"

        sendResponse(headers: headers, body: data, connection: connection)
    }

    private func serveIPA(fileName: String, connection: NWConnection) {
        let ipaUrl = PathConfig.getDirectory(PathConfig.signedAppsFolder).appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: ipaUrl) else {
            sendNotFound(connection: connection)
            return
        }

        let headers = "HTTP/1.1 200 OK\r\n" +
                      "Content-Type: application/octet-stream\r\n" +
                      "Content-Disposition: attachment; filename=\"\(fileName)\"\r\n" +
                      "Content-Length: \(data.count)\r\n" +
                      "Connection: close\r\n\r\n"

        sendResponse(headers: headers, body: data, connection: connection)
    }

    private func sendResponse(headers: String, body: Data, connection: NWConnection) {
        guard let headerData = headers.data(using: .utf8) else {
            connection.cancel()
            return
        }

        var fullData = headerData
        fullData.append(body)

        connection.send(content: fullData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }

    private func sendNotFound(connection: NWConnection) {
        let response = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}
