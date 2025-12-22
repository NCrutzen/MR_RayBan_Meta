import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var glassesManager: GlassesConnectionManager
    @EnvironmentObject var mediaManager: MediaSyncManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Connection Status Card
                    ConnectionStatusCard(isConnected: glassesManager.isConnected)

                    // Quick Stats
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Photos",
                            value: "\(mediaManager.photoCount)",
                            icon: "photo",
                            color: .blue
                        )

                        StatCard(
                            title: "Videos",
                            value: "\(mediaManager.videoCount)",
                            icon: "video",
                            color: .purple
                        )
                    }

                    // Quick Actions
                    QuickActionsCard()

                    // Recent Media Preview
                    RecentMediaCard()
                }
                .padding()
            }
            .navigationTitle("Ray-Ban Meta")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { mediaManager.syncMedia() }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
            }
        }
    }
}

struct ConnectionStatusCard: View {
    let isConnected: Bool

    var body: some View {
        HStack {
            Image(systemName: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title)
                .foregroundStyle(isConnected ? .green : .red)

            VStack(alignment: .leading) {
                Text(isConnected ? "Glasses Connected" : "Glasses Disconnected")
                    .font(.headline)
                Text(isConnected ? "Ray-Ban Meta Wayfarer" : "Open Meta View to connect")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !isConnected {
                Button("Connect") {
                    // Open Meta View app
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct QuickActionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                ActionButton(title: "Sync Media", icon: "arrow.down.circle", color: .blue)
                ActionButton(title: "Live Stream", icon: "video.badge.waveform", color: .red)
                ActionButton(title: "AI Vision", icon: "eye", color: .purple)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct RecentMediaCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Captures")
                    .font(.headline)
                Spacer()
                Button("See All") { }
                    .font(.caption)
            }

            Text("No recent media")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 100)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
        .environmentObject(GlassesConnectionManager())
        .environmentObject(MediaSyncManager())
}
