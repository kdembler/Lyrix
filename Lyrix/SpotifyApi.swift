import Alamofire

enum ApiError: Error {
    case unauthorized
    case failure
    case noPlayerAvailable
}

struct TrackInfo {
    let name: String
    let artists: [String]
}

class SpotifyApi {
    private(set) var auth: SpotifyAuth;

    init() {
        self.auth = SpotifyAuth()
    }

    private func makeRequest<T: Decodable>(of type: T.Type = T.self, url urlSuffix: String, completion: @escaping (Result<T, ApiError>) -> ()) {
        guard let accessToken = self.auth.accessToken else {
            completion(.failure(.unauthorized))
            return
        }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer " + accessToken,
        ]

        let url = apiBaseUrl + urlSuffix

        let response = AF.request(url, headers: headers).validate(statusCode: 200..<300).validate(contentType: ["application/json"])
        response.responseDecodable(of: T.self) { result in
            if result.response?.statusCode == 401 {
                self.auth.refreshToken() { result in
                    switch result {
                    case .success:
                        self.makeRequest(of: T.self, url: urlSuffix, completion: completion)
                    case .failure:
                        completion(.failure(.failure))
                    }
                }
                return
            }
            switch result.result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                switch error {
                case .responseSerializationFailed(let reason):
                    if case .invalidEmptyResponse = reason {
                        completion(.failure(.noPlayerAvailable))
                        return
                    }
                    print("makeRequest for \(url) failed")
                    debugPrint(error)
                    completion(.failure(.failure))
                default:
                    print("makeRequest for \(url) failed")
                    debugPrint(error)
                    completion(.failure(.failure))
                }
            }
        }
    }

    func getCurrentTrackInfo(completion: @escaping (Result<TrackInfo, ApiError>) -> ()) {
        struct SpotifyArtist: Codable {
            let name: String
        }

        struct SpotifyTrack: Codable {
            let name: String
            let artists: [SpotifyArtist]
        }

        struct SpotifyPlayback: Codable {
            let item: SpotifyTrack?
        }

        // TODO: move to me/player/currently-playing
        self.makeRequest(of: SpotifyPlayback.self, url: "/v1/me/player") { result in
            switch result {
            case .success(let playback):
                if playback.item == nil {
                    completion(.failure(.noPlayerAvailable))
                    return
                }
                let artists = playback.item!.artists.map { artist in
                    artist.name
                }
                let trackInfo = TrackInfo(name: playback.item!.name, artists: artists)
                completion(.success(trackInfo))
            case .failure(let reason):
                completion(.failure(reason))
            }
        }
    }
}
