import SwiftUI

public final class ImageCacheService {
    public static let shared = ImageCacheService()
    private let cache = NSCache<NSURL, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("AppIconsCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    public func get(url: URL) -> UIImage? {
        if let memoryImage = cache.object(forKey: url as NSURL) {
            return memoryImage
        }
        let diskPath = cacheDirectory.appendingPathComponent("\(url.absoluteString.hashValue).png")
        if let diskData = try? Data(contentsOf: diskPath), let diskImage = UIImage(data: diskData) {
            cache.setObject(diskImage, forKey: url as NSURL)
            return diskImage
        }
        return nil
    }

    public func set(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
        let diskPath = cacheDirectory.appendingPathComponent("\(url.absoluteString.hashValue).png")
        if let data = image.pngData() {
            try? data.write(to: diskPath)
        }
    }
}

public struct RemoteImageView: View {
    let url: URL
    let cornerRadius: CGFloat

    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false

    public init(url: URL, cornerRadius: CGFloat = 16) {
        self.url = url
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        ZStack {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(white: 0.2))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.7)
                            .opacity(isLoading ? 1 : 0)
                    )
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        if let cached = ImageCacheService.shared.get(url: url) {
            self.loadedImage = cached
            return
        }

        self.isLoading = true

        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.timeoutIntervalForRequest = 25.0

        let session = URLSession(configuration: config)
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 GeraKStore/1.0", forHTTPHeaderField: "User-Agent")

        session.dataTask(with: request) { data, _, _ in
            if let data = data, let img = UIImage(data: data) {
                ImageCacheService.shared.set(img, for: url)
                DispatchQueue.main.async {
                    self.loadedImage = img
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
}
