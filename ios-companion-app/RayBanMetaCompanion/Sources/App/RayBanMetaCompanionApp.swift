import SwiftUI

@main
struct RayBanMetaCompanionApp: App {
    @StateObject private var glassesManager = GlassesConnectionManager()
    @StateObject private var mediaManager = MediaSyncManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(glassesManager)
                .environmentObject(mediaManager)
        }
    }
}
