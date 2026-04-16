import SwiftUI
import AppKit

@main
struct RiftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?

    private let updateStore = UpdateStore()
    private var updateWindowController: UpdateWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register UserDefaults defaults
        UserDefaults.standard.register(defaults: [
            "preset1": 5,
            "preset2": 15,
            "preset3": 25,
            "preset4": 45,
            "preset5": 60,
            "selectedSoundName": "Glass",
            "alarmVolume": 0.7,
            "autoMuteEnabled": true,
            "autoMuteSeconds": 5,
            "autoShowOnComplete": true,
            "floatingDisplayEnabled": false,
            "launchAtLogin": false,
        ])

        NSApp.setActivationPolicy(.accessory)
        menuBarController = MenuBarController()

        // Set up update window and silently check for updates
        updateWindowController = UpdateWindowController(updateStore: updateStore)
        updateStore.checkForUpdates()
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarController?.cleanup()
    }
}
