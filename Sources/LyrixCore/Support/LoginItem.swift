import Foundation
import ServiceManagement

/// Launch-at-login via SMAppService. Only works from a real `.app` bundle — when
/// running the raw SPM executable during development it reports `.notFound`.
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static var isAvailable: Bool {
        SMAppService.mainApp.status != .notFound
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            Log.app.info("login item set to \(enabled)")
        } catch {
            Log.app.error("failed to update login item: \(String(describing: error), privacy: .public)")
        }
    }
}
