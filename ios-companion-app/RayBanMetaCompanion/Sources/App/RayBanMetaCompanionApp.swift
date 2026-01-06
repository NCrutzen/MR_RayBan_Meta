import SwiftUI
import MWDATCore

@main
struct RayBanMetaCompanionApp: App {
    @StateObject private var glassesManager: GlassesConnectionManager
    @StateObject private var mediaManager = MediaSyncManager()

    init() {
        // Initialize SDK before creating GlassesConnectionManager
        do {
            try Wearables.configure()
            print("[App] Wearables SDK configured successfully")
        } catch {
            print("[App] Failed to configure Wearables SDK: \(error)")
        }

        // Create the glasses manager after SDK is configured
        _glassesManager = StateObject(wrappedValue: GlassesConnectionManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(glassesManager)
                .environmentObject(mediaManager)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    // Handle URL callback from Meta AI app after registration
                    Task { @MainActor in
                        let handled = await glassesManager.handleURL(url)
                        print("[App] URL handled: \(handled) - \(url)")
                    }
                }
        }
    }
}
