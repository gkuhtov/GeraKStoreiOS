import Foundation

public final class DownloadManager: NSObject, URLSessionDownloadDelegate {
    public static let shared = DownloadManager()

    private var session: URLSession!
    private var downloadTask: URLSessionDownloadTask?
    private var completionHandler: ((URL?) -> Void)?
    public var progressHandler: ((Float) -> Void)?

    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    public func startDownload(from url: URL, completion: @escaping (URL?) -> Void) {
        self.completionHandler = completion
        downloadTask = session.downloadTask(with: url)
        downloadTask?.resume()
    }

    public func cancel() {
        downloadTask?.cancel()
        downloadTask = nil
    }

    // MARK: - URLSessionDownloadDelegate

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let suggestedName = downloadTask.response?.suggestedFilename ?? "application.ipa"
        let destinationDir = PathConfig.getDirectory(PathConfig.ipaDownloadsFolder)
        let destinationUrl = destinationDir.appendingPathComponent(suggestedName)

        let fileManager = FileManager.default
        try? fileManager.removeItem(at: destinationUrl)

        do {
            try fileManager.moveItem(at: location, to: destinationUrl)
            completionHandler?(destinationUrl)
        } catch {
            print("Ошибка перемещения скачанного IPA: \(error.localizedDescription)")
            completionHandler?(nil)
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        DispatchQueue.main.async { [weak self] in
            self?.progressHandler?(progress)
        }
    }
}
