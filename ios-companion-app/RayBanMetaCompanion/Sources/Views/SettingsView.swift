import SwiftUI
import PhotosUI

struct SettingsView: View {
    @AppStorage("autoSync") private var autoSync = true
    @AppStorage("processNewPhotos") private var processNewPhotos = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("debugMode") private var debugMode = false

    @EnvironmentObject var glassesManager: GlassesConnectionManager

    @State private var showVideoPicker = false
    @State private var showImagePicker = false
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var mockVideoStatus: String?
    @State private var mockImageStatus: String?

    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header
                    headerSection

                    // Sync Settings
                    settingsSection("Sync Settings") {
                        SettingsToggle(title: "Auto-sync Media", isOn: $autoSync)
                        SettingsToggle(title: "Process New Photos", isOn: $processNewPhotos)
                    }

                    // Notifications
                    settingsSection("Notifications") {
                        SettingsToggle(title: "Enable Notifications", isOn: $notificationsEnabled)
                    }

                    // Developer
                    settingsSection("Developer") {
                        SettingsToggle(title: "Debug Mode", isOn: $debugMode)
                    }

                    // Mock Device (for testing without physical glasses)
                    settingsSection("Mock Device Kit") {
                        if glassesManager.isMockDeviceActive {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(MoyneRoberts.success)
                                Text("Mock Device Active")
                                    .foregroundStyle(MoyneRoberts.primary)
                                Spacer()
                            }
                            .padding(.vertical, 4)

                            Divider()
                                .background(MoyneRoberts.secondary.opacity(0.2))

                            // Mock device controls
                            SettingsButton(title: "Power On", icon: "power") {
                                glassesManager.mockPowerOn()
                            }

                            SettingsButton(title: "Unfold (Enable Stream)", icon: "eyeglasses") {
                                glassesManager.mockUnfold()
                            }

                            SettingsButton(title: "Don (Wear)", icon: "person.fill") {
                                glassesManager.mockDon()
                            }

                            Divider()
                                .background(MoyneRoberts.secondary.opacity(0.2))

                            // Mock media selection
                            Text("Mock Media")
                                .font(.caption)
                                .foregroundStyle(MoyneRoberts.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)

                            PhotosPicker(
                                selection: $selectedVideoItem,
                                matching: .videos
                            ) {
                                HStack {
                                    Image(systemName: "video.fill")
                                        .foregroundStyle(MoyneRoberts.accent)
                                    Text("Select Mock Video")
                                        .foregroundStyle(MoyneRoberts.primary)
                                    Spacer()
                                    if let status = mockVideoStatus {
                                        Text(status)
                                            .font(.caption)
                                            .foregroundStyle(MoyneRoberts.success)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(MoyneRoberts.secondary.opacity(0.5))
                                }
                                .padding(.vertical, 4)
                            }

                            PhotosPicker(
                                selection: $selectedImageItem,
                                matching: .images
                            ) {
                                HStack {
                                    Image(systemName: "photo.fill")
                                        .foregroundStyle(MoyneRoberts.accent)
                                    Text("Select Mock Photo")
                                        .foregroundStyle(MoyneRoberts.primary)
                                    Spacer()
                                    if let status = mockImageStatus {
                                        Text(status)
                                            .font(.caption)
                                            .foregroundStyle(MoyneRoberts.success)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(MoyneRoberts.secondary.opacity(0.5))
                                }
                                .padding(.vertical, 4)
                            }

                            Divider()
                                .background(MoyneRoberts.secondary.opacity(0.2))

                            SettingsButton(title: "Unpair Mock Device", icon: "xmark.circle", destructive: true) {
                                glassesManager.unpairMockDevice()
                            }
                        } else {
                            VStack(spacing: 12) {
                                Text("Test without physical Ray-Ban Meta glasses")
                                    .font(.caption)
                                    .foregroundStyle(MoyneRoberts.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                SettingsButton(title: "Pair Mock Device", icon: "plus.circle.fill") {
                                    glassesManager.pairMockDevice()
                                }
                            }
                        }
                    }

                    // About
                    settingsSection("About") {
                        SettingsInfoRow(title: "Version", value: "1.0.0 (Build 1)")
                        SettingsInfoRow(title: "Device", value: UIDevice.current.name)

                        Divider()
                            .background(MoyneRoberts.secondary.opacity(0.2))

                        SettingsLinkRow(title: "Moyne Roberts", url: "https://www.moyneroberts.ie/")
                        SettingsLinkRow(title: "Smeba Fire Safety", url: "https://www.smeba.nl/")
                        SettingsLinkRow(title: "Meta View App", url: "https://apps.apple.com/app/meta-view/id1613849498")
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }

            // Top blur overlay for Dynamic Island
            TopBlurOverlay()
        }
        .onChange(of: selectedVideoItem) { newItem in
            Task {
                await loadMockVideo(from: newItem)
            }
        }
        .onChange(of: selectedImageItem) { newItem in
            Task {
                await loadMockImage(from: newItem)
            }
        }
    }

    // MARK: - Mock Media Loading

    private func loadMockVideo(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        await MainActor.run { mockVideoStatus = "Loading..." }
        print("[Settings] Loading mock video...")

        do {
            // Load video data and save to temp file
            if let data = try await item.loadTransferable(type: Data.self) {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + ".mov")
                try data.write(to: tempURL)
                print("[Settings] Video saved to: \(tempURL)")
                await glassesManager.setMockVideoFeed(fileURL: tempURL)
                await MainActor.run { mockVideoStatus = "Set" }
            } else {
                print("[Settings] Failed to load video data")
                await MainActor.run { mockVideoStatus = "Failed" }
            }
        } catch {
            print("[Settings] Failed to load video: \(error)")
            await MainActor.run { mockVideoStatus = "Error" }
        }
    }

    private func loadMockImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        await MainActor.run { mockImageStatus = "Loading..." }
        print("[Settings] Loading mock image...")

        do {
            // Load image data and save to temp file
            if let data = try await item.loadTransferable(type: Data.self) {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + ".jpg")
                try data.write(to: tempURL)
                print("[Settings] Image saved to: \(tempURL)")
                await glassesManager.setMockCapturedImage(fileURL: tempURL)
                await MainActor.run { mockImageStatus = "Set" }
            } else {
                print("[Settings] Failed to load image data")
                await MainActor.run { mockImageStatus = "Failed" }
            }
        } catch {
            print("[Settings] Failed to load image: \(error)")
            await MainActor.run { mockImageStatus = "Error" }
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                content()
            }
            .cleanCard(cornerRadius: 16, padding: 16)
        }
    }
}

// MARK: - Settings Components

struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .foregroundStyle(MoyneRoberts.primary)
        }
        .tint(MoyneRoberts.accent)
        .padding(.vertical, 4)
    }
}

struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(MoyneRoberts.primary)

            Spacer()

            Text(value)
                .foregroundStyle(MoyneRoberts.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct SettingsLinkRow: View {
    let title: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Text(title)
                    .foregroundStyle(MoyneRoberts.primary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.accent)
            }
            .padding(.vertical, 4)
        }
    }
}

struct SettingsButton: View {
    let title: String
    let icon: String
    var destructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(destructive ? MoyneRoberts.error : MoyneRoberts.accent)

                Text(title)
                    .foregroundStyle(destructive ? MoyneRoberts.error : MoyneRoberts.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.secondary.opacity(0.5))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .environmentObject(GlassesConnectionManager())
}
