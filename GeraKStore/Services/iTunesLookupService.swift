import Foundation

public final class iTunesLookupService {
    public static let shared = iTunesLookupService()
    private var cache: [String: [URL]] = [:]

    private init() {}

    public func fetchScreenshots(bundleId: String, completion: @escaping ([URL]) -> Void) {
        if let cached = cache[bundleId] {
            completion(cached)
            return
        }

        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)&country=ru") else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let first = results.first,
                   let screenshotUrls = first["screenshotUrls"] as? [String] {
                    let urls = screenshotUrls.compactMap { URL(string: $0) }
                    self?.cache[bundleId] = urls
                    DispatchQueue.main.async { completion(urls) }
                    return
                }
            } catch {
                print("Ошибка парсинга iTunes Lookup: \(error.localizedDescription)")
            }

            DispatchQueue.main.async { completion([]) }
        }.resume()
    }
}
