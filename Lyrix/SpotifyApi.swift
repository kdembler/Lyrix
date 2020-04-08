import OAuthSwift
import Alamofire

let redirectUri = "lyrix://oauth-callback/spotify"
let baseUrl = "https://api.spotify.com"
let scopes = "user-read-currently-playing user-read-playback-state"

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
    private var oauth: OAuth2Swift;

    var isAuthenticated: Bool {
        Store.shared.spotifyAccessToken != nil
    }

    init() {
        self.oauth = SpotifyApi.getOauthInstance()
    }

    static func getOauthInstance() -> OAuth2Swift {
        let oauth = OAuth2Swift(
                consumerKey: Store.shared.spotifyApiClient!,
                consumerSecret: Store.shared.spotifyApiSecret!,
                authorizeUrl: authorizeUrl,
                accessTokenUrl: accessTokenUrl,
                responseType: "code"
        )
        oauth.allowMissingStateCheck = true
        return oauth
    }

    func authorize(completion: @escaping (Result<Void, OAuthSwiftError>) -> ()) {
        self.oauth.authorize(
                withCallbackURL: URL(string: redirectUri)!,
                scope: scopes, state: "") { result in
            switch result {
            case .success(let (credentials, _, _)):
                print("Auth success")
                Store.shared.spotifyAccessToken = credentials.oauthToken
                Store.shared.spotifyRefreshToken = credentials.oauthRefreshToken
                completion(.success(()))
            case .failure(let error):
                print("Auth failure")
                debugPrint(error)
                completion(.failure(error))
            }
        }
    }

    private func refreshToken(completion: @escaping (Result<Void, OAuthSwiftError>) -> ()) {
        guard let refreshToken = Store.shared.spotifyRefreshToken else {
            print("No refresh token available")
            return
        }
        self.oauth.renewAccessToken(withRefreshToken: refreshToken) { result in
            switch result {
            case .success(let (credentials, _, _)):
                print("Refresh success")
                Store.shared.spotifyAccessToken = credentials.oauthToken
                Store.shared.spotifyRefreshToken = credentials.oauthRefreshToken
                completion(.success(()))
            case .failure(let error):
                print("Refresh failure")
                debugPrint(error)
                completion(.failure(error))
            }
        }
    }

    func logout(completion: @escaping () -> ()) {
        Store.shared.spotifyAccessToken = nil
        Store.shared.spotifyRefreshToken = nil
        self.oauth = SpotifyApi.getOauthInstance()
        completion()
    }

    func handleAuthCallback(_ event: NSAppleEventDescriptor!) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue, let url = URL(string: urlString) {
            OAuthSwift.handle(url: url)
        } else {
            print("Invalid event string")
        }
    }

    private func makeRequest<T: Decodable>(of type: T.Type = T.self, url urlSuffix: String, completion: @escaping (Result<T, ApiError>) -> ()) {
        guard let accessToken = Store.shared.spotifyAccessToken else {
            completion(.failure(.unauthorized))
            return
        }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer " + accessToken,
        ]

        let url = baseUrl + urlSuffix

        let response = AF.request(url, headers: headers).validate(statusCode: 200..<300).validate(contentType: ["application/json"])
        response.responseDecodable(of: T.self) { result in
            if result.response?.statusCode == 401 {
                self.refreshToken() { result in
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
                        print("no player available")
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

//    func exchangeCodeForToken(code: String, completion: @escaping (Result<OAuthSwift.TokenSuccess, OAuthSwiftError>) -> ()) {
//
//        self.oauthswift!.postOAuthAccessTokenWithRequestToken(byCode: code, callbackURL: URL.init(string: "lyrix://oauth-callback/spotify")!) { result in
//
//            switch result {
//
//            case .failure(let error):
//                print("postOAuthAccessTokenWithRequestToken Error: \(error)")
//                completion(result)
//            case .success(let response):
//
//                print("Received Authorization Token: ")
//                print(response)
//
//                if let access_token = response.parameters["access_token"], let refresh_token = response.parameters["refresh_token"] {
//
//
//                    self.refreshToken = refresh_token as! String
//                    self.accessToken = access_token as! String
//
////                if let t_scope = scope as? String{
////                    let t_vals = t_scope.split(separator:" ")
////                    self.scopes = [String]()
////                    t_vals.forEach({ scopeParameter in
////                        self.scopes.append(String(scopeParameter))
////                    })
////                }
//
////                self.expires = expires as? Int
//
//                    print("ACCESS TOKEN \(String(describing: self.accessToken))")
//                    print("REFRESH TOKEN \(String(describing: self.refreshToken))")
////                print("EXPIRES \(String(describing: self.expires))")
////                print("SCOPE: \(String(describing: self.scopes))")
//
//                    completion(result)
//                }
//            }
//
//        }
//    }
}
