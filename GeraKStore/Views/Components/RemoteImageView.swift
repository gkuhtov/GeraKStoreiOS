import SwiftUI

public final class ImageCacheService {
    public static let shared = ImageCacheService()
    private let cache = NSCache<NSURL, UIImage>()
    private let fileManager = FileManager.default
    private let diskPath: URL

    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        diskPath = paths[0].appendingPathComponent("AppIconsDiskCache")
        try? fileManager.createDirectory(at: diskPath, withIntermediateDirectories: true)
    }

    public func get(for url: URL) -> UIImage? {
        if let memoryImage = cache.object(forKey: url as NSURL) {
            return memoryImage
        }
        let filePath = diskPath.appendingPathComponent("\(abs(url.absoluteString.hashValue)).png")
        if let data = try? Data(contentsOf: filePath), let diskImage = UIImage(data: data) {
            cache.setObject(diskImage, forKey: url as NSURL)
            return diskImage
        }
        return nil
    }

    public func save(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
        let filePath = diskPath.appendingPathComponent("\(abs(url.absoluteString.hashValue)).png")
        if let data = image.pngData() {
            try? data.write(to: filePath, options: .atomic)
        }
    }
}

public struct RemoteImageView: View {
    let url: URL
    let cornerRadius: CGFloat

    @State private var uiImage: UIImage? = nil
    @State private var hasFailed: Bool = false

    public init(url: URL, cornerRadius: CGFloat = 14) {
        self.url = url
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        ZStack {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if hasFailed {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(white: 0.15))
                    .overlay(
                        Image(systemName: "app.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(white: 0.4))
                    )
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(white: 0.15))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.65)
                    )
            }
        }
        .frame(width: 58, height: 58)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            fetchImage(url: url)
        }
    }

    private func fetchImage(url: URL) {
        if let cached = ImageCacheService.shared.get(for: url) {
            self.uiImage = cached
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8.0
        request.setValue("Mozilla/5.0 GeraKStore/1.0", forHTTPHeaderField: "User-Agent")

        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.waitsForConnectivity = false

        let session = URLSession(configuration: config)

        session.dataTask(with: request) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                ImageCacheService.shared.save(image, for: url)
                DispatchQueue.main.async {
                    self.uiImage = image
                    self.hasFailed = false
                }
            } else {
                // Фоллбэк: если это github.io, заменяем на CDN jsdelivr
                let urlStr = url.absoluteString
                if urlStr.contains("gkuhtov.github.io/GeraKStore/") {
                    let fallbackStr = urlStr.replacingOccurrences(of: "https://gkuhtov.github.io/GeraKStore/", with: "https://cdn.jsdelivr.net/gh/gkuhtov/GeraKStore@main/")
                    if let fallbackUrl = URL(string: fallbackStr), fallbackUrl != url {
                        self.fetchImageFallback(url: fallbackUrl)
                        return
                    }
                }
                DispatchQueue.main.async {
                    self.hasFailed = true
                }
            }
        }.resume()
    }

    private func fetchImageFallback(url: URL) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        request.setValue("Mozilla/5.0 GeraKStore/1.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    ImageCacheService.shared.save(image, for: self.url)
                    self.uiImage = image
                    self.hasFailed = false
                } else {
                    self.hasFailed = true
                }
            }
        }.resume()
    }
}
