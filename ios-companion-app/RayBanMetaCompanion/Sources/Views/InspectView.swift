import SwiftUI
import PhotosUI
import Photos

struct InspectView: View {
    @EnvironmentObject var glassesManager: GlassesConnectionManager
    @EnvironmentObject var mediaManager: MediaSyncManager
    @StateObject private var analysisService = FireHazardAnalysisService()

    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingMediaPicker = false
    @State private var showingResultsSheet = false
    @State private var showingBatchInspect = false
    @State private var inspectionHistory: [InspectionResult] = []

    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Main Inspection Card
                    inspectionCard

                    // Quick Actions
                    quickActionsSection

                    // Recent Inspections
                    if !inspectionHistory.isEmpty {
                        recentInspectionsSection
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }

            // Top blur overlay for Dynamic Island
            TopBlurOverlay()
        }
        .sheet(isPresented: $showingResultsSheet) {
            if let result = analysisService.lastAnalysisResult {
                InspectionResultsView(result: result)
            }
        }
        .sheet(isPresented: $showingBatchInspect) {
            BatchInspectView()
                .environmentObject(mediaManager)
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                await loadSelectedPhoto(from: newItem)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Fire Inspect")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("AI-Powered Hazard Analysis")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Connection status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(glassesManager.isConnected ? MoyneRoberts.success : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)

                Text(glassesManager.isConnected ? "Connected" : "Offline")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.15)))
        }
        .padding(.top, 10)
    }

    // MARK: - Main Inspection Card

    private var inspectionCard: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                // Image preview
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 250)
                        .cornerRadius(16)

                    Button(action: { selectedImage = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                            .background(Circle().fill(.white))
                    }
                    .padding(8)
                }

                // Analyze button
                Button(action: analyzeImage) {
                    HStack {
                        if analysisService.isAnalyzing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "flame.fill")
                        }
                        Text(analysisService.isAnalyzing ? "Analyzing..." : "Analyze for Hazards")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(MoyneRoberts.accent))
                }
                .disabled(analysisService.isAnalyzing)

            } else {
                // Empty state - photo selection
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(MoyneRoberts.accent.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "flame.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(MoyneRoberts.accent)
                    }

                    Text("Select a Photo to Inspect")
                        .font(.headline)
                        .foregroundStyle(MoyneRoberts.primary)

                    Text("Use photos from your glasses or photo library")
                        .font(.subheadline)
                        .foregroundStyle(MoyneRoberts.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        // From Glasses Media
                        Button(action: { showingMediaPicker = true }) {
                            Label("From Glasses", systemImage: "eyeglasses")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(MoyneRoberts.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(MoyneRoberts.background))
                        }
                        .buttonStyle(.plain)

                        // From Photo Library
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images
                        ) {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(MoyneRoberts.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(MoyneRoberts.background))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 20)
            }

            // Error display
            if let error = analysisService.analysisError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(MoyneRoberts.warning)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(MoyneRoberts.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(MoyneRoberts.warning.opacity(0.1))
                )
            }
        }
        .cleanCard(cornerRadius: 20, padding: 20)
        .sheet(isPresented: $showingMediaPicker) {
            GlassesMediaPickerView(selectedImage: $selectedImage)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "camera.fill",
                    title: "Live Capture",
                    subtitle: "Stream & Capture"
                ) {
                    // Open camera stream
                }
                .disabled(!glassesManager.isConnected)

                QuickActionButton(
                    icon: "doc.text.viewfinder",
                    title: "Batch Inspect",
                    subtitle: "Multiple Photos"
                ) {
                    showingBatchInspect = true
                }
            }
        }
    }

    // MARK: - Recent Inspections

    private var recentInspectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Inspections")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Button("View All") {
                    // Show full history
                }
                .font(.subheadline)
                .foregroundStyle(MoyneRoberts.accentLight)
            }

            ForEach(inspectionHistory.prefix(3)) { result in
                RecentInspectionRow(result: result)
                    .onTapGesture {
                        analysisService.lastAnalysisResult = result
                        showingResultsSheet = true
                    }
            }
        }
    }

    // MARK: - Actions

    private func loadSelectedPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                }
            }
        } catch {
            print("[InspectView] Failed to load photo: \(error)")
        }
    }

    private func analyzeImage() {
        guard let image = selectedImage else { return }

        Task {
            let result = await analysisService.analyzeImage(image)
            inspectionHistory.insert(result, at: 0)
            showingResultsSheet = true
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(MoyneRoberts.accent)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(MoyneRoberts.primary)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(MoyneRoberts.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .cleanCard(cornerRadius: 16, padding: 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Inspection Row

struct RecentInspectionRow: View {
    let result: InspectionResult

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Image(uiImage: result.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .cornerRadius(12)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: result.overallRisk.iconName)
                        .foregroundStyle(Color(hex: result.overallRisk.color))

                    Text(result.overallRisk.displayName + " Risk")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(MoyneRoberts.primary)
                }

                Text("\(result.hazardCount) hazard(s) found")
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.secondary)

                Text(result.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(MoyneRoberts.secondary.opacity(0.7))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(MoyneRoberts.secondary.opacity(0.5))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Glasses Media Picker

struct GlassesMediaPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var mediaManager: MediaSyncManager
    @Binding var selectedImage: UIImage?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()

                if mediaManager.mediaItems.filter({ $0.type == .photo }).isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.5))

                        Text("No Photos Available")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text("Capture photos with your glasses first")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))

                        Button("Sync Media") {
                            mediaManager.syncMedia()
                        }
                        .buttonStyle(LiquidGlassButtonStyle())
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 4),
                            GridItem(.flexible(), spacing: 4),
                            GridItem(.flexible(), spacing: 4)
                        ], spacing: 4) {
                            ForEach(mediaManager.mediaItems.filter { $0.type == .photo }) { item in
                                SelectableMediaGridItem(item: item) { image in
                                    selectedImage = image
                                    dismiss()
                                }
                            }
                        }
                        .padding(4)
                    }
                }
            }
            .navigationTitle("Select Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Selectable Media Grid Item

struct SelectableMediaGridItem: View {
    let item: MediaItem
    let onSelect: (UIImage) -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: loadFullImage) {
            ZStack {
                Color.white.opacity(0.15)

                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .clipped()
        }
        .buttonStyle(.plain)
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        guard let asset = item.asset else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }

    private func loadFullImage() {
        guard let asset = item.asset else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    onSelect(image)
                }
            }
        }
    }
}

#Preview {
    InspectView()
        .environmentObject(GlassesConnectionManager())
        .environmentObject(MediaSyncManager())
}
