import SwiftUI
import AppKit

@main
struct DynatifyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            ControlCenterView()
                .environmentObject(appDelegate.islandViewModel)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Dynatify") {
                    appDelegate.showAbout()
                }
            }
        }
    }
}
