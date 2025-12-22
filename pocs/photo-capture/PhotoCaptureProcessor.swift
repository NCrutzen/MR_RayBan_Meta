import Foundation
import Vision
import Photos
import UIKit

/// Processes photos captured by Ray-Ban Meta glasses
class PhotoCaptureProcessor: ObservableObject {

    @Published var isProcessing = false
    @Published var lastResults: ProcessingResults?

    private let visionProcessor = VisionProcessor()

    struct ProcessingConfig {
        var enableOCR = true
        var enableObjectDetection = true
        var enableBarcodeScanning = true
        var enableFaceDetection = false
        var enableDocumentScanning = true
        var minConfidence: Float = 0.5
    }

    var config = ProcessingConfig()

    // MARK: - Main Processing

    func process(_ asset: PHAsset) async -> ProcessingResults {
        guard let image = await loadFullImage(asset) else {
            return ProcessingResults()
        }
        return await process(image)
    }

    func process(_ image: UIImage) async -> ProcessingResults {
        await MainActor.run { isProcessing = true }
        defer {
            Task { @MainActor in isProcessing = false }
        }

        var results = ProcessingResults()

        // Run all enabled processors in parallel
        await withTaskGroup(of: Void.self) { group in
            if config.enableOCR {
                group.addTask {
                    results.extractedText = await self.performOCR(on: image)
                }
            }

            if config.enableObjectDetection {
                group.addTask {
                    results.detectedObjects = await self.detectObjects(in: image)
                }
            }

            if config.enableBarcodeScanning {
                group.addTask {
                    results.barcodes = await self.scanBarcodes(in: image)
                }
            }

            if config.enableFaceDetection {
                group.addTask {
                    results.faces = await self.detectFaces(in: image)
                }
            }

            if config.enableDocumentScanning {
                group.addTask {
                    results.documentCorners = await self.detectDocument(in: image)
                }
            }
        }

        await MainActor.run {
            self.lastResults = results
        }

        return results
    }

    // MARK: - Individual Processors

    private func performOCR(on image: UIImage) async -> [ExtractedText] {
        do {
            let texts = try await visionProcessor.extractText(from: image)
            return texts.map { ExtractedText(text: $0, confidence: 1.0) }
        } catch {
            print("OCR failed: \(error)")
            return []
        }
    }

    private func detectObjects(in image: UIImage) async -> [DetectedObject] {
        do {
            let results = try await visionProcessor.classifyObjects(in: image)
            return results
                .filter { $0.confidence >= config.minConfidence }
                .map { DetectedObject(label: $0.identifier, confidence: $0.confidence) }
        } catch {
            print("Object detection failed: \(error)")
            return []
        }
    }

    private func scanBarcodes(in image: UIImage) async -> [ScannedBarcode] {
        do {
            let results = try await visionProcessor.detectBarcodes(in: image)
            return results.map {
                ScannedBarcode(
                    payload: $0.payload,
                    type: BarcodeType(rawValue: $0.symbology) ?? .unknown
                )
            }
        } catch {
            print("Barcode scanning failed: \(error)")
            return []
        }
    }

    private func detectFaces(in image: UIImage) async -> [DetectedFace] {
        do {
            let results = try await visionProcessor.detectFaces(in: image)
            return results.map {
                DetectedFace(boundingBox: $0.boundingBox, confidence: $0.confidence)
            }
        } catch {
            print("Face detection failed: \(error)")
            return []
        }
    }

    private func detectDocument(in image: UIImage) async -> [CGPoint]? {
        do {
            return try await visionProcessor.detectDocument(in: image)
        } catch {
            print("Document detection failed: \(error)")
            return nil
        }
    }

    // MARK: - Helpers

    private func loadFullImage(_ asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

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

// MARK: - Result Types

struct ProcessingResults {
    var extractedText: [ExtractedText] = []
    var detectedObjects: [DetectedObject] = []
    var barcodes: [ScannedBarcode] = []
    var faces: [DetectedFace] = []
    var documentCorners: [CGPoint]?

    var hasContent: Bool {
        !extractedText.isEmpty ||
        !detectedObjects.isEmpty ||
        !barcodes.isEmpty ||
        !faces.isEmpty ||
        documentCorners != nil
    }

    var summary: String {
        var parts: [String] = []

        if !extractedText.isEmpty {
            parts.append("\(extractedText.count) text blocks")
        }
        if !detectedObjects.isEmpty {
            parts.append("\(detectedObjects.count) objects")
        }
        if !barcodes.isEmpty {
            parts.append("\(barcodes.count) barcodes")
        }
        if !faces.isEmpty {
            parts.append("\(faces.count) faces")
        }
        if documentCorners != nil {
            parts.append("document detected")
        }

        return parts.isEmpty ? "No content detected" : parts.joined(separator: ", ")
    }
}

struct ExtractedText: Identifiable {
    let id = UUID()
    let text: String
    let confidence: Float
}

struct DetectedObject: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
}

struct ScannedBarcode: Identifiable {
    let id = UUID()
    let payload: String
    let type: BarcodeType
}

enum BarcodeType: String {
    case qr = "VNBarcodeSymbologyQR"
    case ean13 = "VNBarcodeSymbologyEAN13"
    case ean8 = "VNBarcodeSymbologyEAN8"
    case code128 = "VNBarcodeSymbologyCode128"
    case unknown

    var displayName: String {
        switch self {
        case .qr: return "QR Code"
        case .ean13: return "EAN-13"
        case .ean8: return "EAN-8"
        case .code128: return "Code 128"
        case .unknown: return "Unknown"
        }
    }
}

struct DetectedFace: Identifiable {
    let id = UUID()
    let boundingBox: CGRect
    let confidence: Float
}
