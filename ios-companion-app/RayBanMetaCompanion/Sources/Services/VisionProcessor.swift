import Foundation
import Vision
import UIKit
import CoreML

/// Processes images from glasses using iOS Vision framework
class VisionProcessor {

    // MARK: - Text Recognition (OCR)

    func extractText(from image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return []
        }

        return observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
    }

    // MARK: - Face Detection

    func detectFaces(in image: UIImage) async throws -> [FaceDetectionResult] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectFaceRectanglesRequest()

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return []
        }

        return observations.map { observation in
            FaceDetectionResult(
                boundingBox: observation.boundingBox,
                confidence: observation.confidence
            )
        }
    }

    // MARK: - Face Landmarks

    func detectFaceLandmarks(in image: UIImage) async throws -> [VNFaceObservation] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectFaceLandmarksRequest()

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        return request.results ?? []
    }

    // MARK: - Object Detection

    func classifyObjects(in image: UIImage) async throws -> [ClassificationResult] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNClassifyImageRequest()

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return []
        }

        return observations
            .filter { $0.confidence > 0.5 }
            .prefix(10)
            .map { observation in
                ClassificationResult(
                    identifier: observation.identifier,
                    confidence: observation.confidence
                )
            }
    }

    // MARK: - Barcode/QR Detection

    func detectBarcodes(in image: UIImage) async throws -> [BarcodeResult] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectBarcodesRequest()

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return []
        }

        return observations.compactMap { observation in
            guard let payload = observation.payloadStringValue else { return nil }
            return BarcodeResult(
                payload: payload,
                symbology: observation.symbology.rawValue,
                boundingBox: observation.boundingBox
            )
        }
    }

    // MARK: - Rectangle Detection

    func detectRectangles(in image: UIImage) async throws -> [CGRect] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 10

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return []
        }

        return observations.map { $0.boundingBox }
    }

    // MARK: - Saliency Detection

    func detectSaliency(in image: UIImage, attention: Bool = true) async throws -> [CGRect] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request: VNImageBasedRequest
        if attention {
            request = VNGenerateAttentionBasedSaliencyImageRequest()
        } else {
            request = VNGenerateObjectnessBasedSaliencyImageRequest()
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        if let result = (request.results as? [VNSaliencyImageObservation])?.first {
            return result.salientObjects?.map { $0.boundingBox } ?? []
        }

        return []
    }

    // MARK: - Document Detection

    func detectDocument(in image: UIImage) async throws -> [CGPoint]? {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectDocumentSegmentationRequest()

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first else {
            return nil
        }

        return [
            observation.topLeft,
            observation.topRight,
            observation.bottomRight,
            observation.bottomLeft
        ]
    }
}

// MARK: - Result Types

struct FaceDetectionResult {
    let boundingBox: CGRect
    let confidence: Float
}

struct ClassificationResult {
    let identifier: String
    let confidence: Float
}

struct BarcodeResult {
    let payload: String
    let symbology: String
    let boundingBox: CGRect
}

// MARK: - Errors

enum VisionError: Error, LocalizedError {
    case invalidImage
    case processingFailed
    case modelNotFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process the provided image"
        case .processingFailed:
            return "Vision processing failed"
        case .modelNotFound:
            return "ML model not found"
        }
    }
}
