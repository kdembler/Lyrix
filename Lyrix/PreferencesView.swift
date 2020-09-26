import SwiftUI

struct PreferencesView: View {
    @State private var startupEnabled: Bool = Store.shared.startupEnabled

    var body: some View {
        VStack {
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
        Store.shared.startupEnabled = startupEnabled
        NotificationCenter.default.post(name: preferencesSavedNotification, object: nil)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
