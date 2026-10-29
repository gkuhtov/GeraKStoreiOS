import Foundation

public final class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    public static let shared = DownloadManager()

    @Published public var downloadProgress: Float = 0.0
    public var progressHandler: ((Float) -> Void)?
    private var completionHandler: ((URL?) -> Void)?
    
    private var downloadSession: URLSession!

    private override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60.0
        configuration.timeoutIntervalForResource = 300.0
        self.downloadSession = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
    }

    public func startDownload(from url: URL, completion: @escaping (URL?) -> Void) {
        self.completionHandler = completion
        self.downloadProgress = 0.0
        
        let task = downloadSession.downloadTask(with: url)
        task.resume()
    }

    // Обработка прогресса скачивания
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            self.downloadProgress = progress
            self.progressHandler?(progress)
        }
    }

    // Успешная загрузка файла
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Проверяем HTTP статус ответа
        if let httpResponse = downloadTask.response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            print("Download failed with HTTP status: \(httpResponse.statusCode)")
            self.completionHandler?(nil)
            return
        }

        let downloadsFolder = PathConfig.getDirectory(PathConfig.downloadsFolder)
        let destinationUrl = downloadsFolder.appendingPathComponent(UUID().uuidString + ".ipa")

        do {
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                try FileManager.default.removeItem(at: destinationUrl)
            }
            try FileManager.default.moveItem(at: location, to: destinationUrl)
            self.completionHandler?(destinationUrl)
        } catch {
            print("Ошибка перемещения скачанного файла: \(error)")
            self.completionHandler?(nil)
        }
    }

    // Обработка ошибки загрузки
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Сбой загрузки URLSession: \(error.localizedDescription)")
            self.completionHandler?(nil)
        }
    }
}
