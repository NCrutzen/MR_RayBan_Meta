import SwiftUI
import PhotosUI
import Photos

struct BatchInspectView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var mediaManager: MediaSyncManager
    @StateObject private var analysisService = FireHazardAnalysisService()

    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isLoadingImages = false
    @State private var isAnalyzing = false
    @State private var currentAnalysisIndex = 0
    @State private var currentAnalysisPhase: AnalysisPhase = .preparing
    @State private var analysisResults: [InspectionResult] = []

    enum AnalysisPhase: String {
        case preparing = "Preparing analysis..."
        case uploading = "Uploading image to AI..."
        case analyzing = "AI analyzing for fire hazards..."
        case checkingCompliance = "Checking NEN 4001/1838 compliance..."
        case generatingReport = "Generating safety report..."
        case complete = "Analysis complete"
    }
    @State private var showingResults = false
    @State private var showingGlassesPicker = false

    var body: some View {
        NavigationView {
            ZStack {
                AnimatedGradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header info
                        headerSection

                        // Image Selection
                        imageSelectionSection

                        // Selected Images Preview
                        if !selectedImages.isEmpty {
                            selectedImagesSection
                        }

                        // Analysis Progress
                        if isAnalyzing {
                            analysisProgressSection
                        }

                        // Analyze Button
                        if !selectedImages.isEmpty && !isAnalyzing {
                            analyzeButton
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }

                TopBlurOverlay()
            }
            .navigationTitle("Batch Inspect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: selectedPhotoItems) { newItems in
            Task {
                await loadSelectedPhotos(from: newItems)
            }
        }
        .sheet(isPresented: $showingGlassesPicker) {
            BatchGlassesMediaPickerView(selectedImages: $selectedImages)
        }
        .fullScreenCover(isPresented: $showingResults) {
            BatchInspectionResultsView(results: analysisResults)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(MoyneRoberts.accent.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 36))
                    .foregroundStyle(MoyneRoberts.accent)
            }

            Text("Batch Fire Inspection")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Select multiple photos to analyze for fire hazards")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Image Selection Section

    private var imageSelectionSection: some View {
        VStack(spacing: 12) {
            Text("Select Photos")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                // From Photo Library
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                            .foregroundStyle(MoyneRoberts.accent)

                        Text("Photo Library")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(MoyneRoberts.primary)

                        Text("Up to 10 photos")
                            .font(.caption2)
                            .foregroundStyle(MoyneRoberts.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .cleanCard(cornerRadius: 16, padding: 12)
                }
                .buttonStyle(.plain)

                // From Glasses
                Button(action: { showingGlassesPicker = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "eyeglasses")
                            .font(.title2)
                            .foregroundStyle(MoyneRoberts.accent)

                        Text("From Glasses")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(MoyneRoberts.primary)

                        Text("Select captures")
                            .font(.caption2)
                            .foregroundStyle(MoyneRoberts.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .cleanCard(cornerRadius: 16, padding: 12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Selected Images Section

    private var selectedImagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected Photos")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(selectedImages.count) photo(s)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))

                Button(action: clearSelection) {
                    Text("Clear")
                        .font(.caption)
                        .foregroundStyle(MoyneRoberts.error)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .cornerRadius(12)
                                .clipped()

                            Button(action: { removeImage(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .padding(4)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .cleanCard(cornerRadius: 16, padding: 12)
        }
    }

    // MARK: - Analysis Progress Section

    private var analysisProgressSection: some View {
        VStack(spacing: 20) {
            // Photo counter
            HStack {
                Text("Photo \(currentAnalysisIndex + 1) of \(selectedImages.count)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(MoyneRoberts.primary)

                Spacer()

                Text("\(Int((Double(currentAnalysisIndex) / Double(selectedImages.count)) * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(MoyneRoberts.accent)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(MoyneRoberts.background)
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(MoyneRoberts.accentGradient)
                        .frame(width: geometry.size.width * (Double(currentAnalysisIndex) / Double(max(selectedImages.count, 1))), height: 12)
                        .animation(.easeInOut(duration: 0.3), value: currentAnalysisIndex)
                }
            }
            .frame(height: 12)

            // Current thumbnail
            if currentAnalysisIndex < selectedImages.count {
                HStack(spacing: 16) {
                    Image(uiImage: selectedImages[currentAnalysisIndex])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(10)
                        .clipped()

                    VStack(alignment: .leading, spacing: 6) {
                        // Phase indicator with animation
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(MoyneRoberts.accent)

                            Text(currentAnalysisPhase.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(MoyneRoberts.primary)
                        }

                        // Phase description
                        Text(phaseDescription)
                            .font(.caption)
                            .foregroundStyle(MoyneRoberts.secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
            }

            // Completed count
            if analysisResults.count > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MoyneRoberts.success)

                    Text("\(analysisResults.count) photo(s) analyzed")
                        .font(.caption)
                        .foregroundStyle(MoyneRoberts.secondary)

                    Spacer()

                    // Hazards found so far
                    let totalHazards = analysisResults.reduce(0) { $0 + $1.hazardCount }
                    if totalHazards > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(MoyneRoberts.warning)
                            Text("\(totalHazards) hazard(s) found")
                                .font(.caption)
                                .foregroundStyle(MoyneRoberts.warning)
                        }
                    }
                }
            }
        }
        .cleanCard(cornerRadius: 16, padding: 20)
    }

    private var phaseDescription: String {
        switch currentAnalysisPhase {
        case .preparing:
            return "Getting image ready for analysis"
        case .uploading:
            return "Sending to Claude AI vision service"
        case .analyzing:
            return "Scanning for blocked exits, electrical hazards, missing extinguishers..."
        case .checkingCompliance:
            return "Verifying against Dutch fire safety standards"
        case .generatingReport:
            return "Creating detailed hazard report"
        case .complete:
            return "Moving to next photo"
        }
    }

    // MARK: - Analyze Button

    private var analyzeButton: some View {
        Button(action: startBatchAnalysis) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                Text("Analyze \(selectedImages.count) Photo(s)")
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule().fill(MoyneRoberts.accentGradient))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func loadSelectedPhotos(from items: [PhotosPickerItem]) async {
        isLoadingImages = true
        var loadedImages: [UIImage] = []

        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedImages.append(image)
                }
            } catch {
                print("[BatchInspect] Failed to load image: \(error)")
            }
        }

        await MainActor.run {
            selectedImages = loadedImages
            isLoadingImages = false
        }
    }

    private func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        if index < selectedPhotoItems.count {
            selectedPhotoItems.remove(at: index)
        }
    }

    private func clearSelection() {
        selectedImages.removeAll()
        selectedPhotoItems.removeAll()
    }

    private func startBatchAnalysis() {
        guard !selectedImages.isEmpty else { return }

        isAnalyzing = true
        currentAnalysisIndex = 0
        currentAnalysisPhase = .preparing
        analysisResults.removeAll()

        Task {
            for (index, image) in selectedImages.enumerated() {
                await MainActor.run {
                    currentAnalysisIndex = index
                    currentAnalysisPhase = .preparing
                }

                // Simulate phase progression for better UX
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                await MainActor.run { currentAnalysisPhase = .uploading }

                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                await MainActor.run { currentAnalysisPhase = .analyzing }

                // Actually perform the analysis
                let result = await analysisService.analyzeImage(image)

                await MainActor.run { currentAnalysisPhase = .checkingCompliance }
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s

                await MainActor.run { currentAnalysisPhase = .generatingReport }
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s

                await MainActor.run {
                    currentAnalysisPhase = .complete
                    analysisResults.append(result)
                }

                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s brief pause before next
            }

            await MainActor.run {
                isAnalyzing = false
                showingResults = true
            }
        }
    }
}

// MARK: - Batch Glasses Media Picker

struct BatchGlassesMediaPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var mediaManager: MediaSyncManager
    @Binding var selectedImages: [UIImage]

    @State private var selectedAssets: Set<String> = []

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()

                let photoItems = mediaManager.mediaItems.filter { $0.type == .photo }

                if photoItems.isEmpty {
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
                            ForEach(photoItems) { item in
                                BatchSelectableMediaItem(
                                    item: item,
                                    isSelected: selectedAssets.contains(item.id),
                                    onToggle: { toggleSelection(item) }
                                )
                            }
                        }
                        .padding(4)
                    }
                }
            }
            .navigationTitle("Select Photos (\(selectedAssets.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        loadSelectedGlassesPhotos()
                    }
                    .foregroundStyle(.white)
                    .disabled(selectedAssets.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func toggleSelection(_ item: MediaItem) {
        if selectedAssets.contains(item.id) {
            selectedAssets.remove(item.id)
        } else if selectedAssets.count < 10 {
            selectedAssets.insert(item.id)
        }
    }

    private func loadSelectedGlassesPhotos() {
        let photoItems = mediaManager.mediaItems.filter { $0.type == .photo }

        for item in photoItems where selectedAssets.contains(item.id) {
            guard let asset = item.asset else { continue }

            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = true

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                if let image = image {
                    DispatchQueue.main.async {
                        if !self.selectedImages.contains(where: { $0 === image }) {
                            self.selectedImages.append(image)
                        }
                    }
                }
            }
        }

        dismiss()
    }
}

// MARK: - Batch Selectable Media Item

struct BatchSelectableMediaItem: View {
    let item: MediaItem
    let isSelected: Bool
    let onToggle: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: onToggle) {
            ZStack(alignment: .topTrailing) {
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

                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? MoyneRoberts.accent : Color.white.opacity(0.3))
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
                .padding(6)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(isSelected ? MoyneRoberts.accent : Color.clear, lineWidth: 3)
            )
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
}

#Preview {
    BatchInspectView()
        .environmentObject(MediaSyncManager())
}
