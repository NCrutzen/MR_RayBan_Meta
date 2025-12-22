import SwiftUI

struct POCListView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Active POCs") {
                    NavigationLink(destination: VoiceAssistantPOCView()) {
                        POCRow(
                            title: "Voice Assistant",
                            description: "Custom voice commands and actions",
                            icon: "waveform",
                            status: .active
                        )
                    }

                    NavigationLink(destination: PhotoCapturePOCView()) {
                        POCRow(
                            title: "Photo Capture",
                            description: "Capture and process photos with AI",
                            icon: "camera",
                            status: .active
                        )
                    }

                    NavigationLink(destination: AIVisionPOCView()) {
                        POCRow(
                            title: "AI Vision",
                            description: "Object detection and scene analysis",
                            icon: "eye",
                            status: .development
                        )
                    }

                    NavigationLink(destination: LiveStreamPOCView()) {
                        POCRow(
                            title: "Live Stream",
                            description: "Streaming controls and overlays",
                            icon: "video.badge.waveform",
                            status: .planned
                        )
                    }
                }

                Section("Experimental") {
                    POCRow(
                        title: "Location Awareness",
                        description: "Context-aware notifications",
                        icon: "location",
                        status: .planned
                    )

                    POCRow(
                        title: "Gesture Control",
                        description: "Custom gesture mappings",
                        icon: "hand.tap",
                        status: .planned
                    )
                }
            }
            .navigationTitle("POCs")
        }
    }
}

struct POCRow: View {
    let title: String
    let description: String
    let icon: String
    let status: POCStatus

    enum POCStatus {
        case active, development, planned

        var color: Color {
            switch self {
            case .active: return .green
            case .development: return .orange
            case .planned: return .gray
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 40)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(status.label)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.color.opacity(0.2))
                .foregroundStyle(status.color)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - POC Detail Views

struct VoiceAssistantPOCView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Voice Assistant POC")
                    .font(.largeTitle)
                    .bold()

                Text("This POC demonstrates integration with Meta AI voice commands. Since custom wake words aren't supported, we focus on post-command processing.")
                    .foregroundStyle(.secondary)

                GroupBox("Supported Commands") {
                    VStack(alignment: .leading, spacing: 8) {
                        CommandRow(command: "Hey Meta, take a photo", action: "Triggers photo processing")
                        CommandRow(command: "Hey Meta, what am I looking at?", action: "AI analysis via Meta")
                    }
                }

                GroupBox("How It Works") {
                    Text("1. User issues voice command to glasses\n2. Glasses perform action (e.g., capture photo)\n3. Media syncs to iPhone via Meta View\n4. This app detects new media and processes it")
                        .font(.callout)
                }
            }
            .padding()
        }
        .navigationTitle("Voice Assistant")
    }
}

struct CommandRow: View {
    let command: String
    let action: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(command)
                .font(.system(.callout, design: .monospaced))
            Text(action)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct PhotoCapturePOCView: View {
    @State private var isProcessing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Photo Capture POC")
                    .font(.largeTitle)
                    .bold()

                Text("Demonstrates automatic photo processing using iOS Vision framework on images captured by the glasses.")
                    .foregroundStyle(.secondary)

                GroupBox("Features") {
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "doc.text.viewfinder", text: "Text extraction (OCR)")
                        FeatureRow(icon: "face.smiling", text: "Face detection")
                        FeatureRow(icon: "tag", text: "Object classification")
                        FeatureRow(icon: "barcode", text: "Barcode/QR scanning")
                    }
                }

                Button(action: { isProcessing = true }) {
                    Label("Process Latest Photo", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Photo Capture")
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
            Text(text)
        }
        .padding(.vertical, 2)
    }
}

struct AIVisionPOCView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("AI Vision POC")
                    .font(.largeTitle)
                    .bold()

                Text("Explores advanced computer vision capabilities using Core ML models on glasses-captured images.")
                    .foregroundStyle(.secondary)

                GroupBox("Capabilities") {
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "cube.transparent", text: "3D object recognition")
                        FeatureRow(icon: "text.magnifyingglass", text: "Document analysis")
                        FeatureRow(icon: "person.2.crop.square.stack", text: "Person identification")
                        FeatureRow(icon: "map", text: "Scene classification")
                    }
                }

                Text("Status: In Development")
                    .foregroundStyle(.orange)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
        .navigationTitle("AI Vision")
    }
}

struct LiveStreamPOCView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Live Stream POC")
                    .font(.largeTitle)
                    .bold()

                Text("Control and enhance live streaming from glasses to Facebook/Instagram.")
                    .foregroundStyle(.secondary)

                GroupBox("Planned Features") {
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "text.bubble", text: "Comment overlay display")
                        FeatureRow(icon: "clock", text: "Stream timer controls")
                        FeatureRow(icon: "bell", text: "Viewer notifications")
                        FeatureRow(icon: "record.circle", text: "Recording controls")
                    }
                }

                Text("Status: Planned")
                    .foregroundStyle(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
        .navigationTitle("Live Stream")
    }
}

#Preview {
    POCListView()
}
