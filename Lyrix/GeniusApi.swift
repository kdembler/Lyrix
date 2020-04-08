import Alamofire

struct GeniusSongResult: Codable {
    let url: String
}

struct GeniusSongHit: Codable {
    let result: GeniusSongResult
}

struct GeniusSearchResponse: Codable {
    let hits: [GeniusSongHit]
}

struct GeniusSearchResult: Codable {
    let response: GeniusSearchResponse
}

let apiEndpoint = "https://api.genius.com/search"

class GeniusApi {

    static func getLyricsLink(track: TrackInfo, completion: @escaping (Result<String, Error>) -> ()) {
        let trackString = prepareTrackString(track: track)
        let searchUrlString = "\(apiEndpoint)?q=\(trackString)"
        guard let searchUrl = URL(string: searchUrlString) else {
            print("Failed to build URL")
            debugPrint(searchUrlString)
            return
        }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(geniusToken)",
        ]

        let response = AF.request(searchUrl, headers: headers).validate(statusCode: 200..<300).validate(contentType: ["application/json"])
        response.responseDecodable(of: GeniusSearchResult.self) { result in
            switch result.result {
            case .success(let data):
                let hits = data.response.hits
                if hits.count > 0 {
                    completion(.success(hits[0].result.url))
                } else {
                    print("No results!")
                }
            case .failure(let error):
                print("Failed genius search")
                debugPrint(error)
                completion(.failure(error))
            }
        }
    }

    static func prepareTrackString(track: TrackInfo) -> String {
        let artist = self.sanitizeValue(track.artists[0])
        let name = self.sanitizeValue(track.name)
        return "\(artist) \(name)".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
    }

    static func sanitizeValue(_ val: String) -> String {
        // TODO: rework
        var str = val
        if let range = val.lowercased().range(of: " (feat.") {
            str = String(val.prefix(upTo: range.lowerBound))
        } else if let range = val.lowercased().range(of: " (with ") {
            str = String(val.prefix(upTo: range.lowerBound))
        } else if let range = val.lowercased().range(of: " feat.") {
            str = String(val.prefix(upTo: range.lowerBound))
        }
        return str
    }
}
