import Foundation
import Photos
import Combine
import UIKit

/// Manages media synchronization from Ray-Ban Meta glasses via Photos library
class MediaSyncManager: NSObject, ObservableObject {
    @Published var mediaItems: [MediaItem] = []
    @Published var photoCount: Int = 0
    @Published var videoCount: Int = 0
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    private var photoLibraryObserver: PHPhotoLibraryChangeObserver?

    override init() {
        super.init()
        requestPhotoLibraryAccess()
    }

    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    self?.startMonitoring()
                    self?.syncMedia()
                }
            }
        }
    }

    func startMonitoring() {
        PHPhotoLibrary.shared().register(self)
    }

    func syncMedia() {
        guard !isSyncing else { return }

        isSyncing = true

        Task {
            await fetchRecentMedia()
            await MainActor.run {
                isSyncing = false
                lastSyncDate = Date()
            }
        }
    }

    private func fetchRecentMedia() async {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 100

        // Fetch photos
        let photoResults = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        // Fetch videos
        let videoResults = PHAsset.fetchAssets(with: .video, options: fetchOptions)

        // Build items array using index-based access (Swift 6 concurrency safe)
        let photoItems: [MediaItem] = (0..<photoResults.count).map { i in
            MediaItem(asset: photoResults.object(at: i), type: .photo)
        }

        let videoItems: [MediaItem] = (0..<videoResults.count).map { i in
            MediaItem(asset: videoResults.object(at: i), type: .video)
        }

        // Combine and sort by creation date
        let sortedItems = (photoItems + videoItems).sorted {
            ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast)
        }

        let photoTotal = photoResults.count
        let videoTotal = videoResults.count

        await MainActor.run {
            self.mediaItems = sortedItems
            self.photoCount = photoTotal
            self.videoCount = videoTotal
        }
    }

    func loadThumbnail(for item: MediaItem, targetSize: CGSize = CGSize(width: 200, height: 200)) async -> UIImage? {
        guard let asset = item.asset else { return nil }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    func loadFullImage(for item: MediaItem) async -> UIImage? {
        guard let asset = item.asset else { return nil }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension MediaSyncManager: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            self?.syncMedia()
        }
    }
}
