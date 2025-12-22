import Foundation
import Photos
import UserNotifications

/// Handles voice command post-processing for Ray-Ban Meta glasses
class VoiceCommandHandler: ObservableObject {
    @Published var lastProcessedPhoto: ProcessedPhoto?
    @Published var processingQueue: [String] = []

    private let visionProcessor = VisionProcessor()
    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Photo Processing

    func processNewPhoto(asset: PHAsset) async {
        guard let image = await loadImage(from: asset) else { return }

        let processedPhoto = ProcessedPhoto(
            id: asset.localIdentifier,
            timestamp: asset.creationDate ?? Date()
        )

        // Run all detection tasks in parallel
        async let textResult = extractText(from: image)
        async let objectsResult = classifyObjects(from: image)
        async let barcodesResult = detectBarcodes(from: image)

        let (text, objects, barcodes) = await (textResult, objectsResult, barcodesResult)

        processedPhoto.extractedText = text
        processedPhoto.detectedObjects = objects
        processedPhoto.detectedBarcodes = barcodes

        await MainActor.run {
            self.lastProcessedPhoto = processedPhoto
        }

        // Trigger actions based on content
        await triggerActions(for: processedPhoto)
    }

    // MARK: - Vision Processing

    private func extractText(from image: UIImage) async -> [String] {
        do {
            return try await visionProcessor.extractText(from: image)
        } catch {
            print("Text extraction failed: \(error)")
            return []
        }
    }

    private func classifyObjects(from image: UIImage) async -> [String] {
        do {
            let results = try await visionProcessor.classifyObjects(in: image)
            return results.map { "\($0.identifier) (\(Int($0.confidence * 100))%)" }
        } catch {
            print("Object classification failed: \(error)")
            return []
        }
    }

    private func detectBarcodes(from image: UIImage) async -> [String] {
        do {
            let results = try await visionProcessor.detectBarcodes(in: image)
            return results.map { $0.payload }
        } catch {
            print("Barcode detection failed: \(error)")
            return []
        }
    }

    // MARK: - Action Triggers

    private func triggerActions(for photo: ProcessedPhoto) async {
        // Check for actionable content

        // 1. QR Code detected - offer to open URL
        if let urlString = photo.detectedBarcodes.first(where: { $0.hasPrefix("http") }) {
            await sendNotification(
                title: "QR Code Detected",
                body: "Tap to open: \(urlString)",
                action: .openURL(urlString)
            )
        }

        // 2. Text detected - offer to copy
        if !photo.extractedText.isEmpty {
            let textPreview = photo.extractedText.joined(separator: " ").prefix(100)
            await sendNotification(
                title: "Text Detected",
                body: String(textPreview),
                action: .copyText(photo.extractedText.joined(separator: "\n"))
            )
        }

        // 3. Specific object detected - trigger custom action
        if photo.detectedObjects.contains(where: { $0.contains("document") }) {
            await sendNotification(
                title: "Document Detected",
                body: "Would you like to scan and save this document?",
                action: .scanDocument
            )
        }
    }

    // MARK: - Notifications

    private func sendNotification(title: String, body: String, action: NotificationAction) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = action.categoryIdentifier
        content.userInfo = action.userInfo

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    // MARK: - Helpers

    private func loadImage(from asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
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

// MARK: - Supporting Types

class ProcessedPhoto: ObservableObject, Identifiable {
    let id: String
    let timestamp: Date

    @Published var extractedText: [String] = []
    @Published var detectedObjects: [String] = []
    @Published var detectedBarcodes: [String] = []

    init(id: String, timestamp: Date) {
        self.id = id
        self.timestamp = timestamp
    }
}

enum NotificationAction {
    case openURL(String)
    case copyText(String)
    case scanDocument
    case none

    var categoryIdentifier: String {
        switch self {
        case .openURL: return "OPEN_URL"
        case .copyText: return "COPY_TEXT"
        case .scanDocument: return "SCAN_DOCUMENT"
        case .none: return "DEFAULT"
        }
    }

    var userInfo: [String: Any] {
        switch self {
        case .openURL(let url):
            return ["url": url]
        case .copyText(let text):
            return ["text": text]
        case .scanDocument:
            return ["action": "scan"]
        case .none:
            return [:]
        }
    }
}
