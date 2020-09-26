import Foundation
import AppKit
import Alamofire
import CommonCrypto

let notificationUrlKey = "callbackURL"

enum SpotifyAuthError: Error {
    case failure
    case stateError
    case authorizeError
}

struct AuthResponse: Codable {
    let access_token: String
    let refresh_token: String
}

class SpotifyAuth {
    var isAuthenticated: Bool {
        Store.shared.spotifyAccessToken != nil
    }

    private(set) var accessToken: String? {
        get {
            Store.shared.spotifyAccessToken
        }
        set {
            Store.shared.spotifyAccessToken = newValue
        }
    }

    private(set) var refreshToken: String? {
        get {
            Store.shared.spotifyRefreshToken
        }
        set {
            Store.shared.spotifyRefreshToken = newValue
        }
    }

    private var pkceVerifier: String?
    private var pkceChallenge: String?
    private var state: String?
    private var notificationCenter = NotificationCenter()
    private var callbackObserver: NSObjectProtocol?

    func authorize(completion: @escaping (Result<Void, SpotifyAuthError>) -> ()) {
        self.removeCallbackObserver()

        do {
            try generatePKCEVerifierChallenge()
        } catch {
            completion(.failure(.failure))
            return
        }
        generateState()

        var authorizeUrlComponent = URLComponents(string: authorizeUrl)
        let authorizeQueryItems: [URLQueryItem] = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: self.pkceChallenge),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: scopes),
        ]
        authorizeUrlComponent?.queryItems = authorizeQueryItems


        if let readyUrl = authorizeUrlComponent?.url {
            print("opening authorize URL: '\(readyUrl)'")
            NSWorkspace.shared.open(readyUrl)
        } else {
            print("Failed to create the authorize URL")
            completion(.failure(.failure))
            return
        }

        self.callbackObserver = self.notificationCenter.addObserver(forName: authorizeCallbackHandledNotification, object: nil, queue: OperationQueue.main) { notification in
            self.removeCallbackObserver()

            if let callbackUrl = notification.userInfo?[notificationUrlKey] as? String {
                let callbackComponents = URLComponents(string: callbackUrl)
                if let queryItems = callbackComponents?.queryItems {
                    var state: String?
                    var code: String?
                    var error: String?

                    for item in queryItems {
                        switch item.name {
                        case "state":
                            state = item.value
                            break
                        case "code":
                            code = item.value
                            break
                        case "error":
                            error = item.value
                            break
                        default:
                            print("Unexpected item in callback URL")
                            debugPrint(item)
                        }
                    }

                    if state != self.state {
                        print("state mismatch! is: '\(state)' should be: '\(self.state)'")
                        debugPrint(callbackUrl)
                        completion(.failure(.stateError))
                        return
                    }

                    if let error = error {
                        print("callbackUrl contained error")
                        debugPrint(error)
                        debugPrint(callbackUrl)
                        completion(.failure(.authorizeError))
                        return
                    }

                    if let code = code {
                        self.exchangeCodeForToken(code: code, completion: completion)
                    } else {
                        print("callbackUrl doesn't have code")
                        debugPrint(callbackUrl)
                        completion(.failure(.authorizeError))
                        return
                    }
                } else {
                    print("callbackNotification failed to parse callbackUrl: \(callbackUrl)")
                    completion(.failure(.failure))
                    return
                }
            } else {
                print("callbackNotification doesn't have callbackUrl")
                debugPrint(notification.userInfo as Any)
                completion(.failure(.failure))
            }
        }
    }

    func refreshToken(completion: @escaping (Result<Void, SpotifyAuthError>) -> ()) {
        let parameters: [String: String] = [
            "client_id": clientID,
            "grant_type": "refresh_token",
            "refresh_token": self.refreshToken!,
        ]

        self.makeTokenRequest(parameters: parameters) { result in
            switch result {
            case .success:
                print("Refresh success")
                completion(.success(()))
                break
            case .failure(let reason):
                print("Refresh failure")
                completion(.failure(reason))
            }
        }
    }

    func logout(completion: @escaping () -> ()) {
        self.accessToken = nil
        self.refreshToken = nil
        completion()
    }

    func handleAuthCallback(_ event: NSAppleEventDescriptor!) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue {
            let userInfo = [
                notificationUrlKey: urlString
            ]
            self.notificationCenter.post(name: authorizeCallbackHandledNotification, object: nil, userInfo: userInfo)
        } else {
            print("Invalid event string")
        }
    }

    private func exchangeCodeForToken(code: String, completion: @escaping (Result<Void, SpotifyAuthError>) -> ()) {
        let parameters: [String: String] = [
            "client_id": clientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectUri,
            "code_verifier": self.pkceVerifier!,
        ]

        self.makeTokenRequest(parameters: parameters) { result in
            switch result {
            case .success:
                print("Auth success")
                completion(.success(()))
                break
            case .failure(let reason):
                print("Auth failure")
                completion(.failure(reason))
            }
        }
    }

    private func makeTokenRequest(parameters: [String: String], completion: @escaping (Result<Void, SpotifyAuthError>) -> ()) {
        let request = AF.request(accessTokenUrl, method: .post, parameters: parameters).validate(statusCode: 200..<300).validate(contentType: ["application/json"])
        request.responseDecodable(of: AuthResponse.self) { response in
            switch response.result {
            case .success(let data):
                self.accessToken = data.access_token
                self.refreshToken = data.refresh_token
                completion(.success(()))
                break
            case .failure:
                if let data = response.data {
                    if let bodyString = String(data: data, encoding: .utf8) {
                        print(bodyString)
                    } else {
                        print("Couldn't decode body")
                    }
                } else {
                    print("No body")
                }
                completion(.failure(.authorizeError))
                break
            }
        }
    }

    private func removeCallbackObserver() {
        if let callbackObserver = self.callbackObserver {
            self.notificationCenter.removeObserver(callbackObserver)
        }
    }

    private func generateState() {
        self.state = generateRandomString(length: 32)
    }

    private func generatePKCEVerifierChallenge() throws {
        let verifierLength = randomInteger(min: 43, max: 128)
        let verifier = generateRandomString(length: verifierLength)

        guard let verifierData = verifier.data(using: String.Encoding.utf8) else {
            throw SpotifyAuthError.failure
        }
        var buffer = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        _ = verifierData.withUnsafeBytes {
            CC_SHA256($0.baseAddress, CC_LONG(verifierData.count), &buffer)
        }
        let hash = Data(_: buffer)
        let challenge = hash.base64EncodedData()
        let encodedChallenge = String(decoding: challenge, as: UTF8.self)
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
                .trimmingCharacters(in: .whitespaces)
        self.pkceVerifier = verifier
        self.pkceChallenge = encodedChallenge
    }
}

private func randomInteger(min: Int, max: Int) -> Int {
    let bytesCount = 4
    var uinteger: UInt32 = 0
    var buffer = [UInt8](repeating: 0, count: bytesCount)

    _ = SecRandomCopyBytes(kSecRandomDefault, bytesCount, &buffer)

    NSData(bytes: buffer, length: bytesCount)
            .getBytes(&uinteger, length: bytesCount)

    let integer = Int(uinteger)
    return min + integer % (max - min + 1)
}

func generateRandomString(length: Int) -> String {
    let bufferLength = Int(ceil(Double(length) / 1.3))
    var buffer = [UInt8](repeating: 0, count: bufferLength)

    _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)

    let encoded = Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)

    return String(encoded.prefix(length))
}
