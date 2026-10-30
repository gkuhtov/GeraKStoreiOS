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
            parameters.includePeerToPeer = true

            self.listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)

            self.listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.isRunning = true
                    print("OTA сервер активен на всех интерфейсах (порт \(self?.port ?? 8080))")
                case .failed(let error):
                    print("Ошибка OTA сервера: \(error.localizedDescription)")
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

        var rangeHeader: String? = nil
        for line in lines {
            if line.lowercased().hasPrefix("range: bytes=") {
                rangeHeader = String(line.dropFirst(13)).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        if path.hasSuffix(".plist") {
            serveFile(name: (path as NSString).lastPathComponent, mime: "text/xml; charset=utf-8", isHead: isHead, range: nil, connection: connection)
        } else if path.hasSuffix(".ipa") {
            serveFile(name: (path as NSString).lastPathComponent, mime: "application/octet-stream", isHead: isHead, range: rangeHeader, connection: connection)
        } else {
            sendSimpleResponse(status: "404 Not Found", body: nil, connection: connection)
        }
    }

    private func serveFile(name: String, mime: String, isHead: Bool, range: String?, connection: NWConnection) {
        let fileUrl = PathConfig.getDirectory(PathConfig.signedAppsFolder).appendingPathComponent(name)

        guard FileManager.default.fileExists(atPath: fileUrl.path),
              let attrs = try? FileManager.default.attributesOfItem(atPath: fileUrl.path),
              let totalSize = attrs[.size] as? UInt64 else {
            sendSimpleResponse(status: "404 Not Found", body: nil, connection: connection)
            return
        }

        var startOffset: UInt64 = 0
        var endOffset: UInt64 = totalSize - 1
        var isPartial = false

        if let range = range {
            let components = range.split(separator: "-")
            if let first = components.first, let start = UInt64(first) {
                startOffset = start
                isPartial = true
            }
            if components.count > 1, let end = UInt64(components[1]) {
                endOffset = min(end, totalSize - 1)
                isPartial = true
            }
        }

        let contentLength = endOffset - startOffset + 1
        let statusCode = isPartial ? "206 Partial Content" : "200 OK"

        var headerStr = "HTTP/1.1 \(statusCode)\r\n" +
                        "Content-Type: \(mime)\r\n" +
                        "Content-Length: \(contentLength)\r\n" +
                        "Accept-Ranges: bytes\r\n" +
                        "Access-Control-Allow-Origin: *\r\n"

        if isPartial {
            headerStr += "Content-Range: bytes \(startOffset)-\(endOffset)/\(totalSize)\r\n"
        }
        headerStr += "Connection: close\r\n\r\n"

        if isHead {
            connection.send(content: headerStr.data(using: .utf8), completion: .contentProcessed { _ in
                connection.cancel()
            })
            return
        }

        guard let handle = try? FileHandle(forReadingFrom: fileUrl) else {
            sendSimpleResponse(status: "500 Internal Server Error", body: nil, connection: connection)
            return
        }

        try? handle.seek(toOffset: startOffset)

        connection.send(content: headerStr.data(using: .utf8), isComplete: false, completion: .contentProcessed { [weak self] error in
            if error != nil {
                try? handle.close()
                connection.cancel()
                return
            }
            self?.streamFileChunked(handle: handle, bytesRemaining: contentLength, connection: connection)
        })
    }

    private func streamFileChunked(handle: FileHandle, bytesRemaining: UInt64, connection: NWConnection) {
        guard bytesRemaining > 0 else {
            try? handle.close()
            connection.cancel()
            return
        }

        let chunkSize = min(UInt64(512 * 1024), bytesRemaining)
        let data = handle.readData(ofLength: Int(chunkSize))

        if data.isEmpty {
            try? handle.close()
            connection.cancel()
            return
        }

        let remaining = bytesRemaining - UInt64(data.count)
        connection.send(content: data, isComplete: false, completion: .contentProcessed { [weak self] error in
            if error != nil {
                try? handle.close()
                connection.cancel()
                return
            }
            self?.streamFileChunked(handle: handle, bytesRemaining: remaining, connection: connection)
        })
    }

    private func sendSimpleResponse(status: String, body: Data?, connection: NWConnection) {
        let len = body?.count ?? 0
        let res = "HTTP/1.1 \(status)\r\nContent-Length: \(len)\r\nConnection: close\r\n\r\n"
        var out = res.data(using: .utf8) ?? Data()
        if let body = body { out.append(body) }
        connection.send(content: out, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
