import SwiftUI

struct ContentView: View {
    @EnvironmentObject var glassesManager: GlassesConnectionManager
    @EnvironmentObject var mediaManager: MediaSyncManager

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "eyeglasses")
                }

            MediaGalleryView()
                .tabItem {
                    Label("Media", systemImage: "photo.stack")
                }

            POCListView()
                .tabItem {
                    Label("POCs", systemImage: "lightbulb")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GlassesConnectionManager())
        .environmentObject(MediaSyncManager())
}
