import Foundation

public final class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate, URLSessionTaskDelegate {
    public static let shared = DownloadManager()

    @Published public var downloadProgress: Float = 0.0
    public var progressHandler: ((Float) -> Void)?
    private var completionHandler: ((URL?) -> Void)?

    private var currentTask: URLSessionDownloadTask?
    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.waitsForConnectivity = false
        config.timeoutIntervalForRequest = 45.0
        config.timeoutIntervalForResource = 1200.0 // 20 минут на большие игры
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }()

    private override init() {
        super.init()
    }

    public func startDownload(from url: URL, completion: @escaping (URL?) -> Void) {
        self.completionHandler = completion
        self.downloadProgress = 0.0

        currentTask?.cancel()

        var request = URLRequest(url: url)
        request.timeoutInterval = 45.0
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("*/*", forHTTPHeaderField: "Accept")

        let task = downloadSession.downloadTask(with: request)
        self.currentTask = task
        task.resume()
    }

    // Сохранение сессии и заголовков при редиректах GitHub -> AWS S3
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        var redirectedRequest = request
        redirectedRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        completionHandler(redirectedRequest)
    }

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        DispatchQueue.main.async {
            if totalBytesExpectedToWrite > 0 {
                let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                self.downloadProgress = progress
                self.progressHandler?(progress)
            } else {
                self.progressHandler?(0.15)
            }
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let httpResponse = downloadTask.response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            print("Download failed: HTTP \(httpResponse.statusCode)")
            DispatchQueue.main.async {
                self.completionHandler?(nil)
            }
            return
        }

        let downloadsFolder = PathConfig.getDirectory(PathConfig.downloadsFolder)
        let destinationUrl = downloadsFolder.appendingPathComponent("\(UUID().uuidString).ipa")

        do {
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                try FileManager.default.removeItem(at: destinationUrl)
            }
            try FileManager.default.moveItem(at: location, to: destinationUrl)
            DispatchQueue.main.async {
                self.completionHandler?(destinationUrl)
            }
        } catch {
            print("Move failed: \(error)")
            DispatchQueue.main.async {
                self.completionHandler?(nil)
            }
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.completionHandler?(nil)
            }
        }
    }
}
