import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var glassesManager: GlassesConnectionManager
    @EnvironmentObject var mediaManager: MediaSyncManager
    @Binding var selectedTab: Int
    @State private var showCameraStream = false

    var body: some View {
        ZStack {
            // Static corporate background
            AnimatedGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Connection Status Card
                    connectionCard

                    // Main Action - Fire Inspection
                    inspectionCard

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            // Top blur overlay for Dynamic Island
            TopBlurOverlay()
        }
        .fullScreenCover(isPresented: $showCameraStream) {
            CameraStreamView()
                .environmentObject(glassesManager)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(MoyneRoberts.companyName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(MoyneRoberts.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Connection indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(glassesManager.isConnected ? MoyneRoberts.success : Color.white.opacity(0.3))
                    .frame(width: 10, height: 10)

                Text(glassesManager.isConnected ? "Connected" : "Offline")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
            )
        }
        .padding(.top, 8)
    }

    // MARK: - Connection Card

    private var connectionCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Glasses icon
                ZStack {
                    Circle()
                        .fill(connectionStatusColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    if isSearching {
                        ProgressView()
                            .tint(MoyneRoberts.primary)
                    } else {
                        Image(systemName: "eyeglasses")
                            .font(.system(size: 24))
                            .foregroundStyle(connectionStatusColor)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(connectionStatusTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(MoyneRoberts.primary)

                    Text(connectionDescription)
                        .font(.subheadline)
                        .foregroundStyle(MoyneRoberts.secondary)
                }

                Spacer()

                connectionButton
            }
        }
        .cleanCard()
    }

    private var isSearching: Bool {
        glassesManager.connectionStatus == .searching || glassesManager.connectionStatus == .connecting
    }

    private var connectionStatusColor: Color {
        switch glassesManager.connectionStatus {
        case .connected:
            return MoyneRoberts.success
        case .searching, .connecting:
            return MoyneRoberts.accent
        case .permissionRequired:
            return MoyneRoberts.error
        case .disconnected:
            return MoyneRoberts.secondary
        }
    }

    private var connectionStatusTitle: String {
        switch glassesManager.connectionStatus {
        case .connected:
            return "Glasses Connected"
        case .searching:
            return "Searching..."
        case .connecting:
            return "Connecting..."
        case .permissionRequired:
            return "Permission Required"
        case .disconnected:
            return "No Glasses Detected"
        }
    }

    private var connectionDescription: String {
        switch glassesManager.connectionStatus {
        case .connected:
            return glassesManager.glassesModel
        case .searching:
            return "Looking for nearby glasses"
        case .connecting:
            return "Establishing connection"
        case .permissionRequired:
            return "Grant camera access"
        case .disconnected:
            return "Tap Search to connect"
        }
    }

    @ViewBuilder
    private var connectionButton: some View {
        switch glassesManager.connectionStatus {
        case .connected:
            Button(action: { showCameraStream = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "video.fill")
                    Text("Stream")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .fixedSize()
            }
            .buttonStyle(CorporateButtonStyle())

        case .searching, .connecting:
            EmptyView()

        case .disconnected, .permissionRequired:
            Button("Search") {
                glassesManager.startSearching()
            }
            .buttonStyle(CorporateButtonStyle())
        }
    }

    // MARK: - Inspection Card

    private var inspectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(MoyneRoberts.warning)

                Text("Fire Safety Inspection")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(MoyneRoberts.primary)

                Spacer()
            }

            Text("Use AI-powered analysis to identify fire hazards in your environment. Capture photos with your glasses or select from your library.")
                .font(.subheadline)
                .foregroundStyle(MoyneRoberts.secondary)
                .lineSpacing(4)

            HStack(spacing: 12) {
                // Photo count badge
                if mediaManager.photoCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.fill")
                            .font(.caption)
                        Text("\(mediaManager.photoCount) photos")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(MoyneRoberts.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(MoyneRoberts.background)
                    )
                }

                Spacer()

                // Go to Inspect button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 1  // Inspect tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Start Inspection")
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(MoyneRoberts.accent)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .cleanCard()
    }
}

// MARK: - Corporate Button Style

struct CorporateButtonStyle: ButtonStyle {
    var isPrimary: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(isPrimary ? .white : MoyneRoberts.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isPrimary ? MoyneRoberts.accent : MoyneRoberts.background)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    DashboardView(selectedTab: .constant(0))
        .environmentObject(GlassesConnectionManager())
        .environmentObject(MediaSyncManager())
}
