import Foundation
import Network
import Security

public final class OTAServer {
    public static let shared = OTAServer()

    private var listener: NWListener?
    public let port: UInt16 = 8443
    private var isRunning: Bool = false

    private init() {}

    public func start() {
        guard !isRunning else { return }

        do {
            let tlsOptions = NWProtocolTLS.Options()
            sec_protocol_options_set_verify_block(tlsOptions.securityProtocolOptions, { _, _, sec_protocol_verify_complete in
                sec_protocol_verify_complete(true)
            }, .global())

            let parameters = NWParameters(tls: tlsOptions, tcp: NWProtocolTCP.Options())
            parameters.allowLocalEndpointReuse = true

            self.listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)

            self.listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.isRunning = true
                    print("OTA HTTPS Сервер активен на порту \(self?.port ?? 8443)")
                case .failed(let error):
                    print("Ошибка OTA Сервера: \(error.localizedDescription)")
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
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, _ in
            guard let self = self, let data = data, let req = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }
            self.processHttpRequest(request: req, connection: connection)
        }
    }

    private func processHttpRequest(request: String, connection: NWConnection) {
        let lines = request.components(separatedBy: "\r\n")
        guard let firstLine = lines.first, firstLine.hasPrefix("GET") else {
            connection.cancel()
            return
        }

        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            connection.cancel()
            return
        }

        let path = parts[1].split(separator: "?").first.map(String.init) ?? parts[1]

        if path == "/manifest.plist" {
            serveFile(name: "manifest.plist", mime: "text/xml", connection: connection)
        } else if path.hasSuffix(".ipa") {
            let fileName = (path as NSString).lastPathComponent
            serveFile(name: fileName, mime: "application/octet-stream", connection: connection)
        } else {
            let notFound = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
            connection.send(content: notFound.data(using: .utf8), completion: .contentProcessed({ _ in connection.cancel() }))
        }
    }

    private func serveFile(name: String, mime: String, connection: NWConnection) {
        let fileUrl = PathConfig.getDirectory(PathConfig.signedAppsFolder).appendingPathComponent(name)
        guard let data = try? Data(contentsOf: fileUrl) else {
            let notFound = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
            connection.send(content: notFound.data(using: .utf8), completion: .contentProcessed({ _ in connection.cancel() }))
            return
        }

        let headers = "HTTP/1.1 200 OK\r\n" +
                      "Content-Type: \(mime)\r\n" +
                      "Content-Length: \(data.count)\r\n" +
                      "Access-Control-Allow-Origin: *\r\n" +
                      "Connection: close\r\n\r\n"

        var responseData = headers.data(using: .utf8) ?? Data()
        responseData.append(data)

        connection.send(content: responseData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}
