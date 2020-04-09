import SwiftUI

struct PreferencesView: View {
    @State private var spotifyApiClient: String = Store.shared.spotifyApiClient ?? ""
    @State private var spotifyApiSecret: String = Store.shared.spotifyApiSecret ?? ""
    @State private var startupEnabled: Bool = Store.shared.startupEnabled

    var body: some View {
        VStack {
            Text("Spotify API Client ID")
            TextField("Spotify API Client ID", text: $spotifyApiClient)
            Text("Spotify API Secret")
            TextField("Spotify API Secret", text: $spotifyApiSecret)
            Toggle(isOn: $startupEnabled) {
                Text("Launch at startup")
            }
            Button(action: save) {
                Text("Save")
            }
        }
                .padding(10)
                .frame(width: 300)
    }

    func save() {
        Store.shared.spotifyApiClient = spotifyApiClient
        Store.shared.spotifyApiSecret = spotifyApiSecret
        Store.shared.startupEnabled = startupEnabled
        NotificationCenter.default.post(name: preferencesSavedNotification, object: nil)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
