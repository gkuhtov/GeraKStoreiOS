import Foundation
import Network

public final class OTAServer {
    public static let shared = OTAServer()

    private var listener: NWListener?
    public let port: UInt16 = 8080
    private var isRunning: Bool = false

    private init() {}

    public func start() {
        guard !isRunning else { return }

        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true

            self.listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)

            self.listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.isRunning = true
                    print("Локальный OTA HTTP-сервер активен на порту \(self?.port ?? 8080)")
                case .failed(let error):
                    print("Сбой OTA-сервера: \(error.localizedDescription)")
                    self?.stop()
                default:
                    break
                }
            }

            self.listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }

            self.listener?.start(queue: .global(qos: .userInitiated))
        } catch {
            print("Ошибка запуска NWListener: \(error.localizedDescription)")
        }
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        receiveRequest(connection)
    }

    private func receiveRequest(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16384) { [weak self] data, _, _, _ in
            guard let self = self, let data = data, let req = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }
            self.processHttpRequest(request: req, connection: connection)
        }
    }

    private func processHttpRequest(request: String, connection: NWConnection) {
        let lines = request.components(separatedBy: "\r\n")
        guard let firstLine = lines.first, firstLine.hasPrefix("GET") || firstLine.hasPrefix("HEAD") else {
            connection.cancel()
            return
        }

        let isHead = firstLine.hasPrefix("HEAD")
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            connection.cancel()
            return
        }

        let rawPath = parts[1].split(separator: "?").first.map(String.init) ?? parts[1]
        let path = (rawPath as NSString).removingPercentEncoding ?? rawPath

        if path.hasSuffix(".plist") {
            serveFile(name: (path as NSString).lastPathComponent, mime: "text/xml", isHead: isHead, connection: connection)
        } else if path.hasSuffix(".ipa") {
            serveFile(name: (path as NSString).lastPathComponent, mime: "application/octet-stream", isHead: isHead, connection: connection)
        } else {
            sendResponse(status: "404 Not Found", headers: [:], body: nil, connection: connection)
        }
    }

    private func serveFile(name: String, mime: String, isHead: Bool, connection: NWConnection) {
        let fileUrl = PathConfig.getDirectory(PathConfig.signedAppsFolder).appendingPathComponent(name)

        guard FileManager.default.fileExists(atPath: fileUrl.path),
              let attributes = try? FileManager.default.attributesOfItem(atPath: fileUrl.path),
              let fileSize = attributes[.size] as? UInt64 else {
            sendResponse(status: "404 Not Found", headers: [:], body: nil, connection: connection)
            return
        }

        let headers: [String: String] = [
            "Content-Type": mime,
            "Content-Length": "\(fileSize)",
            "Accept-Ranges": "bytes",
            "Access-Control-Allow-Origin": "*",
            "Connection": "close"
        ]

        if isHead {
            sendResponse(status: "200 OK", headers: headers, body: nil, connection: connection)
            return
        }

        guard let fileHandle = try? FileHandle(forReadingFrom: fileUrl) else {
            sendResponse(status: "500 Internal Server Error", headers: [:], body: nil, connection: connection)
            return
        }

        // Отправка заголовков
        var headerStr = "HTTP/1.1 200 OK\r\n"
        for (k, v) in headers {
            headerStr += "\(k): \(v)\r\n"
        }
        headerStr += "\r\n"

        connection.send(content: headerStr.data(using: .utf8), isComplete: false, completion: .contentProcessed { [weak self] error in
            if error != nil {
                try? fileHandle.close()
                connection.cancel()
                return
            }
            self?.streamFile(handle: fileHandle, connection: connection)
        })
    }

    private func streamFile(handle: FileHandle, connection: NWConnection) {
        let chunkSize = 512 * 1024 // 512 KB чанки для плавной передачи больших IPA
        let data = handle.readData(ofLength: chunkSize)

        if data.isEmpty {
            try? handle.close()
            connection.cancel()
            return
        }

        connection.send(content: data, isComplete: false, completion: .contentProcessed { [weak self] error in
            if error != nil {
                try? handle.close()
                connection.cancel()
                return
            }
            self?.streamFile(handle: handle, connection: connection)
        })
    }

    private func sendResponse(status: String, headers: [String: String], body: Data?, connection: NWConnection) {
        var headerStr = "HTTP/1.1 \(status)\r\n"
        var allHeaders = headers
        if let body = body {
            allHeaders["Content-Length"] = "\(body.count)"
        } else if allHeaders["Content-Length"] == nil {
            allHeaders["Content-Length"] = "0"
        }
        allHeaders["Connection"] = "close"

        for (k, v) in allHeaders {
            headerStr += "\(k): \(v)\r\n"
        }
        headerStr += "\r\n"

        var response = headerStr.data(using: .utf8) ?? Data()
        if let body = body {
            response.append(body)
        }

        connection.send(content: response, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
