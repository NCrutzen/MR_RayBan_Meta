import SwiftUI

struct POCListView: View {
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header
                    headerSection

                    // Active Features
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Active Features")

                        FeatureCard(
                            icon: "waveform",
                            title: "Voice Assistant",
                            description: "Custom voice commands and actions",
                            status: .active,
                            destination: AnyView(VoiceAssistantPOCView())
                        )

                        FeatureCard(
                            icon: "camera.fill",
                            title: "Photo Capture",
                            description: "Capture and process photos with AI",
                            status: .active,
                            destination: AnyView(PhotoCapturePOCView())
                        )

                        FeatureCard(
                            icon: "eye.fill",
                            title: "AI Vision",
                            description: "Object detection and scene analysis",
                            status: .development,
                            destination: AnyView(AIVisionPOCView())
                        )

                        FeatureCard(
                            icon: "video.badge.waveform.fill",
                            title: "Live Stream",
                            description: "Streaming controls and overlays",
                            status: .planned,
                            destination: AnyView(LiveStreamPOCView())
                        )
                    }

                    // Experimental Features
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Experimental")

                        FeatureCard(
                            icon: "location.fill",
                            title: "Location Awareness",
                            description: "Context-aware notifications",
                            status: .planned,
                            destination: nil
                        )

                        FeatureCard(
                            icon: "hand.tap.fill",
                            title: "Gesture Control",
                            description: "Custom gesture mappings",
                            status: .planned,
                            destination: nil
                        )
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Features")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white.opacity(0.8))
            .padding(.top, 8)
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let status: FeatureStatus
    let destination: AnyView?

    enum FeatureStatus {
        case active, development, planned

        var color: Color {
            switch self {
            case .active: return MoyneRoberts.success
            case .development: return MoyneRoberts.warning
            case .planned: return MoyneRoberts.secondary
            }
        }

        var label: String {
            switch self {
            case .active: return "Active"
            case .development: return "In Dev"
            case .planned: return "Planned"
            }
        }
    }

    var body: some View {
        Group {
            if let destination = destination {
                NavigationLink(destination: destination) {
                    cardContent
                }
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(MoyneRoberts.accent.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(MoyneRoberts.accent)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Status badge
            Text(status.label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(status.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(status.color.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(status.color.opacity(0.3), lineWidth: 1)
                        )
                )

            if destination != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .liquidGlassCard(cornerRadius: 20, padding: 16)
    }
}

// MARK: - POC Detail Views

struct VoiceAssistantPOCView: View {
    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Voice Assistant")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("This feature demonstrates integration with Meta AI voice commands.")
                        .foregroundStyle(.white.opacity(0.8))

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Supported Commands")
                            .font(.headline)
                            .foregroundStyle(.white)

                        CommandItem(command: "Hey Meta, take a photo", action: "Triggers photo processing")
                        CommandItem(command: "Hey Meta, what am I looking at?", action: "AI analysis via Meta")
                    }
                    .liquidGlassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("How It Works")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text("1. User issues voice command to glasses\n2. Glasses perform action (e.g., capture photo)\n3. Media syncs to iPhone via Meta View\n4. This app detects new media and processes it")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .liquidGlassCard()

                    Spacer(minLength: 100)
                }
                .padding(20)
            }
        }
    }
}

struct CommandItem: View {
    let command: String
    let action: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(command)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.white)

            Text(action)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.vertical, 4)
    }
}

struct PhotoCapturePOCView: View {
    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Photo Capture")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Automatic photo processing using iOS Vision framework.")
                        .foregroundStyle(.white.opacity(0.8))

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                            .foregroundStyle(.white)

                        FeatureItem(icon: "doc.text.viewfinder", text: "Text Recognition (OCR)")
                        FeatureItem(icon: "face.smiling", text: "Face Detection")
                        FeatureItem(icon: "tag.fill", text: "Object Classification")
                        FeatureItem(icon: "barcode", text: "Barcode/QR Scanning")
                    }
                    .liquidGlassCard()

                    Button(action: {}) {
                        Label("Process Latest Photo", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LiquidGlassButtonStyle())

                    Spacer(minLength: 100)
                }
                .padding(20)
            }
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(MoyneRoberts.accent)
                .frame(width: 24)

            Text(text)
                .foregroundStyle(.white)
        }
        .padding(.vertical, 2)
    }
}

struct AIVisionPOCView: View {
    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("AI Vision")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Advanced computer vision with Core ML models.")
                        .foregroundStyle(.white.opacity(0.8))

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Capabilities")
                            .font(.headline)
                            .foregroundStyle(.white)

                        FeatureItem(icon: "cube.transparent", text: "3D Object Recognition")
                        FeatureItem(icon: "text.magnifyingglass", text: "Document Analysis")
                        FeatureItem(icon: "person.2.crop.square.stack", text: "Person Identification")
                        FeatureItem(icon: "map.fill", text: "Scene Classification")
                    }
                    .liquidGlassCard()

                    HStack {
                        Text("Status: In Development")
                            .font(.headline)
                            .foregroundStyle(MoyneRoberts.warning)
                    }
                    .frame(maxWidth: .infinity)
                    .liquidGlassCard()

                    Spacer(minLength: 100)
                }
                .padding(20)
            }
        }
    }
}

struct LiveStreamPOCView: View {
    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Live Stream")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Control and enhance live streaming from glasses.")
                        .foregroundStyle(.white.opacity(0.8))

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Planned Features")
                            .font(.headline)
                            .foregroundStyle(.white)

                        FeatureItem(icon: "text.bubble.fill", text: "Comment Overlay Display")
                        FeatureItem(icon: "clock.fill", text: "Stream Timer Controls")
                        FeatureItem(icon: "bell.fill", text: "Viewer Notifications")
                        FeatureItem(icon: "record.circle", text: "Recording Controls")
                    }
                    .liquidGlassCard()

                    HStack {
                        Text("Status: Planned")
                            .font(.headline)
                            .foregroundStyle(MoyneRoberts.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .liquidGlassCard()

                    Spacer(minLength: 100)
                }
                .padding(20)
            }
        }
    }
}

#Preview {
    NavigationStack {
        POCListView()
    }
}
