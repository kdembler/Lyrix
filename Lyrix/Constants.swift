import Foundation

let appIdentifier = "dev.kdembler.Lyrix"
let launcherIdentifier = "dev.kdembler.LyrixLauncher"
let apiBaseUrl = "https://api.spotify.com"
let authorizeUrl = "https://accounts.spotify.com/authorize"
let accessTokenUrl = "https://accounts.spotify.com/api/token"
let clientID = "0238be12311d40b1a96aea3af50a1d0c"
let redirectUri = "lyrix://oauth-callback/spotify"
let scopes = "user-read-currently-playing user-read-playback-state"
let preferencesSavedNotification = Notification.Name("PreferencesSaved")
let killLauncherNotification = Notification.Name("KillLauncher")
let authorizeCallbackHandledNotification = Notification.Name("AuthorizeCallbackHandled")
let geniusToken = "8W9Uq9vyoFPNTiIL3djSBxhrcSdO9J2oWRiuhqynWcr44W3Dy1i3q8DqcPFR34zd"
