import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let runningApps = NSWorkspace.shared.runningApplications
        let appRunning = !runningApps.filter {
            $0.bundleIdentifier == appIdentifier
        }.isEmpty

        if !appRunning {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(terminate), name: killLauncherNotification, object: appIdentifier)

            let bundlePath = Bundle.main.bundlePath as NSString
            var components = bundlePath.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("Lyrix")

            let appPath = NSString.path(withComponents: components)
            NSWorkspace.shared.launchApplication(appPath)
        } else {
            terminate()
        }
    }

    @objc func terminate() {
        NSApp.terminate(nil)
    }
}
