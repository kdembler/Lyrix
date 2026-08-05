import Foundation

struct GeniusHit {
    let title: String
    let artist: String
    let url: URL
    let isInstrumental: Bool
    let hasLyrics: Bool
}

enum GeniusError: Error {
    case badResponse(status: Int)
    case malformedURL
}

/// Talks to Genius search.
///
/// Deliberately ships without a bundled credential — v2 hardcoded one in
/// `electron/constants.ts` and it leaked into public git history. The tokenless
/// `genius.com/api/search` endpoint returns the same payload shape as the official
/// `api.genius.com/search`, so an optional user-supplied token is a drop-in upgrade
/// rather than a different code path.
final class GeniusClient {
    private let session: URLSession
    /// Optional user-supplied API token. When absent we use the tokenless endpoint.
    var accessToken: String?

    init(accessToken: String? = nil) {
        self.accessToken = accessToken

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 8
        configuration.waitsForConnectivity = false
        self.session = URLSession(configuration: configuration)
    }

    func search(query: String) async throws -> [GeniusHit] {
        let base = accessToken == nil
            ? "https://genius.com/api/search"
            : "https://api.genius.com/search"

        guard var components = URLComponents(string: base) else { throw GeniusError.malformedURL }
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = components.url else { throw GeniusError.malformedURL }

        var request = URLRequest(url: url)
        request.setValue("Lyrix/2.0 (+https://github.com/kdembler/Lyrix)", forHTTPHeaderField: "User-Agent")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GeniusError.badResponse(status: -1)
        }
        guard http.statusCode == 200 else {
            throw GeniusError.badResponse(status: http.statusCode)
        }

        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.response.hits.compactMap { hit in
            guard hit.type == "song", let url = URL(string: hit.result.url) else { return nil }
            return GeniusHit(
                title: hit.result.title,
                artist: hit.result.primaryArtist.name,
                url: url,
                isInstrumental: hit.result.instrumental ?? false,
                hasLyrics: (hit.result.lyricsState ?? "complete") == "complete"
            )
        }
    }

    /// Always-available fallback: needs no API, no token, and cannot fail to construct.
    /// This is what makes "the click never does nothing" true.
    static func searchPageURL(for track: Track) -> URL {
        var components = URLComponents(string: "https://genius.com/search")!
        components.queryItems = [URLQueryItem(name: "q", value: track.searchQuery)]
        return components.url ?? URL(string: "https://genius.com")!
    }

    // MARK: - Wire format

    private struct SearchResponse: Decodable {
        let response: Response

        struct Response: Decodable {
            let hits: [Hit]
        }

        struct Hit: Decodable {
            let type: String
            let result: Result
        }

        struct Result: Decodable {
            let title: String
            let url: String
            let instrumental: Bool?
            let lyricsState: String?
            let primaryArtist: Artist

            enum CodingKeys: String, CodingKey {
                case title, url, instrumental
                case lyricsState = "lyrics_state"
                case primaryArtist = "primary_artist"
            }
        }

        struct Artist: Decodable {
            let name: String
        }
    }
}
