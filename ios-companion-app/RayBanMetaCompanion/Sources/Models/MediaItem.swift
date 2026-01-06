import Foundation
import Photos
import UIKit

/// Represents a media item captured by Ray-Ban Meta glasses
struct MediaItem: Identifiable {
    let id: String
    let type: MediaType
    let creationDate: Date?
    let duration: TimeInterval?
    let asset: PHAsset?

    var thumbnail: UIImage?

    enum MediaType {
        case photo
        case video
    }

    init(asset: PHAsset, type: MediaType) {
        self.id = asset.localIdentifier
        self.type = type
        self.creationDate = asset.creationDate
        self.duration = type == .video ? asset.duration : nil
        self.asset = asset
    }

    init(id: String = UUID().uuidString,
         type: MediaType,
         creationDate: Date? = nil,
         duration: TimeInterval? = nil) {
        self.id = id
        self.type = type
        self.creationDate = creationDate
        self.duration = duration
        self.asset = nil
    }
}

// MARK: - Formatting Extensions

extension MediaItem {
    var formattedDate: String {
        guard let date = creationDate else { return "Unknown" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var formattedDuration: String? {
        guard let duration = duration else { return nil }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration)
    }
}
