import SwiftUI
import Photos

struct MediaGalleryView: View {
    @EnvironmentObject var mediaManager: MediaSyncManager
    @State private var selectedFilter: MediaFilter = .all

    enum MediaFilter: String, CaseIterable {
        case all = "All"
        case photos = "Photos"
        case videos = "Videos"
    }

    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Filter Pills
                filterSection

                // Content
                if mediaManager.mediaItems.isEmpty {
                    emptyStateView
                } else {
                    mediaGrid
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Media")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Spacer()

            Button(action: { mediaManager.syncMedia() }) {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(IconGlassButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        HStack(spacing: 12) {
            ForEach(MediaFilter.allCases, id: \.self) { filter in
                FilterPill(
                    title: filter.rawValue,
                    isSelected: selectedFilter == filter
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = filter
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text("No Media Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text("Photos and videos from your smart glasses will appear here")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: { mediaManager.syncMedia() }) {
                Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(MoyneRoberts.accent))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Media Grid

    private var mediaGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ], spacing: 4) {
                ForEach(filteredMedia) { item in
                    MediaGridItem(item: item)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 100)
        }
    }

    var filteredMedia: [MediaItem] {
        switch selectedFilter {
        case .all:
            return mediaManager.mediaItems
        case .photos:
            return mediaManager.mediaItems.filter { $0.type == .photo }
        case .videos:
            return mediaManager.mediaItems.filter { $0.type == .video }
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? MoyneRoberts.accent : Color.white.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(isSelected ? 0.3 : 0.1), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Media Grid Item

struct MediaGridItem: View {
    let item: MediaItem
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            Color.white.opacity(0.15)
                .aspectRatio(1, contentMode: .fill)

            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ProgressView()
                    .tint(.white)
            }

            // Video indicator
            if item.type == .video {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                            .padding(8)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        guard let asset = item.asset else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast

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

// MARK: - Legacy Thumbnail View (kept for compatibility)

struct MediaThumbnailView: View {
    let item: MediaItem

    var body: some View {
        MediaGridItem(item: item)
    }
}

#Preview {
    MediaGalleryView()
        .environmentObject(MediaSyncManager())
}
