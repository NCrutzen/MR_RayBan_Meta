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
        NavigationStack {
            VStack {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(MediaFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if mediaManager.mediaItems.isEmpty {
                    ContentUnavailableView(
                        "No Media",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Photos and videos captured with your glasses will appear here after syncing.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 2) {
                            ForEach(filteredMedia) { item in
                                MediaThumbnailView(item: item)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Media")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { mediaManager.syncMedia() }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
            }
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

struct MediaThumbnailView: View {
    let item: MediaItem

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle()
                .fill(.gray.opacity(0.2))
                .aspectRatio(1, contentMode: .fill)

            if let thumbnail = item.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: item.type == .photo ? "photo" : "video")
                    .foregroundStyle(.secondary)
            }

            if item.type == .video {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                    .padding(4)
            }
        }
        .clipped()
    }
}

#Preview {
    MediaGalleryView()
        .environmentObject(MediaSyncManager())
}
