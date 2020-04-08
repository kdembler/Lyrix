import SwiftUI

struct PreferencesView: View {
    @State private var spotifyApiClient: String = Store.shared.spotifyApiClient ?? ""
    @State private var spotifyApiSecret: String = Store.shared.spotifyApiSecret ?? ""
    
    var body: some View {
        VStack {
            TextField("Spotify API Client ID", text: $spotifyApiClient)
            TextField("Spotify API Secret", text: $spotifyApiSecret)
            Button(action: save) {
                Text("Save")
            }
        }
        .padding(10)
        .frame(width: 300)
    }

    init() {

    }
    
    func save() {
        Store.shared.spotifyApiClient = spotifyApiClient
        Store.shared.spotifyApiSecret = spotifyApiSecret
        NotificationCenter.default.post(name: preferencesSavedNotification, object: nil)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
