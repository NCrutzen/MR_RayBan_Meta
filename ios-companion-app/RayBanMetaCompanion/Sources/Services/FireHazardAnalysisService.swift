import Foundation
import UIKit

/// Service for analyzing images for fire hazards using AI
@MainActor
class FireHazardAnalysisService: ObservableObject {
    // MARK: - Published Properties

    @Published var isAnalyzing = false
    @Published var lastAnalysisResult: InspectionResult?
    @Published var analysisError: String?

    // MARK: - Configuration

    private let apiKey: String?
    private let baseURL = "https://api.orq.ai/v2/deployments/invoke"
    private let deploymentKey = "Fire_Safety_Analyses"

    init() {
        // Load Orq.ai API key from environment variable
        let envKey = ProcessInfo.processInfo.environment["ORQ_API_KEY"]
        let plistKey = Bundle.main.object(forInfoDictionaryKey: "ORQ_API_KEY") as? String

        // Filter out unexpanded build variables like "$(ORQ_API_KEY)"
        let validPlistKey = plistKey?.hasPrefix("$(") == true ? nil : plistKey

        self.apiKey = envKey ?? validPlistKey

        if self.apiKey != nil {
            print("[FireHazardAnalysis] API key loaded successfully")
        } else {
            print("[FireHazardAnalysis] WARNING: No ORQ_API_KEY found")
        }
    }

    // MARK: - Public Methods

    /// Analyze an image for fire hazards
    func analyzeImage(_ image: UIImage) async -> InspectionResult {
        isAnalyzing = true
        analysisError = nil

        defer { isAnalyzing = false }

        // If no API key, use local analysis
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            print("[FireHazardAnalysis] No API key found, using local analysis")
            return await performLocalAnalysis(image)
        }

        do {
            let result = try await performOrqAnalysis(image, apiKey: apiKey)
            lastAnalysisResult = result
            return result
        } catch {
            print("[FireHazardAnalysis] Orq.ai API error: \(error)")
            analysisError = error.localizedDescription
            // Fallback to local analysis
            return await performLocalAnalysis(image)
        }
    }

    // MARK: - Orq.ai Deployment Analysis

    private func performOrqAnalysis(_ image: UIImage, apiKey: String) async throws -> InspectionResult {
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AnalysisError.imageConversionFailed
        }
        let base64Image = imageData.base64EncodedString()

        // Build the message content with image
        let messageContent: [[String: Any]] = [
            [
                "type": "image_url",
                "image_url": [
                    "url": "data:image/jpeg;base64,\(base64Image)"
                ]
            ],
            [
                "type": "text",
                "text": "Analyze this image for fire safety hazards."
            ]
        ]

        // Orq.ai deployment request body
        let requestBody: [String: Any] = [
            "key": deploymentKey,
            "messages": [
                [
                    "role": "user",
                    "content": messageContent
                ]
            ],
            "context": [
                "environments": []
            ],
            "metadata": [
                "source": "ios-companion-app",
                "analysis_type": "fire_safety"
            ]
        ]

        guard let url = URL(string: baseURL) else {
            throw AnalysisError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120 // Allow up to 2 minutes for image analysis
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("[FireHazardAnalysis] Sending request to Orq.ai deployment: \(deploymentKey)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnalysisError.invalidResponse
        }

        print("[FireHazardAnalysis] Orq.ai response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[FireHazardAnalysis] Orq.ai API error \(httpResponse.statusCode): \(errorMessage)")
            throw AnalysisError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        // Parse the Orq.ai response
        // Response structure: { "choices": [{ "message": { "content": "..." } }] }
        let responseJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Debug: print response structure
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[FireHazardAnalysis] Response preview: \(String(jsonString.prefix(500)))...")
        }

        guard let choices = responseJson?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            print("[FireHazardAnalysis] Failed to parse Orq.ai response structure")
            throw AnalysisError.parsingFailed
        }

        print("[FireHazardAnalysis] Received analysis response, parsing...")

        // Parse the JSON response from the deployment
        return try parseAnalysisResponse(content, originalImage: image)
    }

    private func parseAnalysisResponse(_ jsonString: String, originalImage: UIImage) throws -> InspectionResult {
        // Clean up the JSON string (remove markdown code blocks if present)
        var cleanJson = jsonString
        if cleanJson.hasPrefix("```json") {
            cleanJson = String(cleanJson.dropFirst(7))
        } else if cleanJson.hasPrefix("```") {
            cleanJson = String(cleanJson.dropFirst(3))
        }
        if cleanJson.hasSuffix("```") {
            cleanJson = String(cleanJson.dropLast(3))
        }
        cleanJson = cleanJson.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanJson.data(using: .utf8) else {
            throw AnalysisError.parsingFailed
        }

        let decoder = JSONDecoder()
        let orqResponse = try decoder.decode(OrqAnalysisResponse.self, from: jsonData)

        // Map risk_rating from Orq response to HazardSeverity
        func mapRiskRating(_ rating: String) -> HazardSeverity {
            switch rating.lowercased() {
            case "critical": return .critical
            case "high": return .high
            case "medium": return .medium
            case "low": return .low
            default: return .medium
            }
        }

        // Map risk_level from header to RiskLevel
        func mapRiskLevel(_ level: String) -> RiskLevel {
            switch level.lowercased() {
            case "critical": return .critical
            case "high": return .high
            case "medium": return .medium
            case "low": return .low
            default: return .medium
            }
        }

        // Convert Orq hazards to FireHazard
        let hazards = orqResponse.identified_hazards.map { hazard in
            FireHazard(
                type: hazard.title,
                description: hazard.description,
                severity: mapRiskRating(hazard.riskValue),
                recommendation: hazard.recommended_action
            )
        }

        // Convert Orq safety compliance to SafetyCompliance
        // Use .status property to extract boolean from either format
        let safetyCompliance = SafetyCompliance(
            fireExtinguisherVisible: orqResponse.safety_compliance.fire_extinguisher_visible.status,
            exitSignsVisible: orqResponse.safety_compliance.exit_signs_visible.status,
            clearEgressPath: orqResponse.safety_compliance.clear_egress_path.status,
            electricalHazards: orqResponse.safety_compliance.electrical_hazards_present.status,
            flammableMaterialsStored: orqResponse.safety_compliance.flammable_materials_stored_properly.status
        )

        return InspectionResult(
            id: UUID(),
            timestamp: Date(),
            image: originalImage,
            overallRisk: mapRiskLevel(orqResponse.header.risk_level),
            hazards: hazards,
            safetyCompliance: safetyCompliance,
            summary: orqResponse.summary,
            recommendations: orqResponse.recommendations,
            source: .claudeAI
        )
    }

    // MARK: - Local Analysis (Fallback)

    private func performLocalAnalysis(_ image: UIImage) async -> InspectionResult {
        print("[FireHazardAnalysis] Performing local Vision-based analysis")

        let visionProcessor = VisionProcessor()
        var hazards: [FireHazard] = []
        var recommendations: [String] = []

        // Classify objects in the image
        do {
            let classifications = try await visionProcessor.classifyObjects(in: image)

            // Check for fire-related classifications
            let fireRelatedTerms = ["fire", "flame", "smoke", "electrical", "wire", "cable",
                                    "outlet", "container", "box", "storage", "clutter"]

            for classification in classifications {
                let identifier = classification.identifier.lowercased()

                if fireRelatedTerms.contains(where: { identifier.contains($0) }) {
                    hazards.append(FireHazard(
                        type: "Detected: \(classification.identifier)",
                        description: "Object detected with \(Int(classification.confidence * 100))% confidence",
                        severity: classification.confidence > 0.8 ? .medium : .low,
                        recommendation: "Review this area for potential fire hazards"
                    ))
                }
            }
        } catch {
            print("[FireHazardAnalysis] Object classification failed: \(error)")
        }

        // Detect text (for signs, labels)
        do {
            let texts = try await visionProcessor.extractText(from: image)
            let warningTerms = ["warning", "danger", "fire", "exit", "emergency", "flammable", "caution"]

            for text in texts {
                if warningTerms.contains(where: { text.lowercased().contains($0) }) {
                    recommendations.append("Safety signage detected: \"\(text)\"")
                }
            }
        } catch {
            print("[FireHazardAnalysis] Text extraction failed: \(error)")
        }

        // Generate summary based on findings
        let overallRisk: RiskLevel
        let summary: String

        if hazards.isEmpty {
            overallRisk = .low
            summary = "No obvious fire hazards detected. For comprehensive analysis, connect to AI service."
            recommendations.append("Consider professional fire safety inspection for thorough assessment")
        } else {
            overallRisk = hazards.contains(where: { $0.severity == .high || $0.severity == .critical }) ? .high : .medium
            summary = "Found \(hazards.count) potential area(s) of concern. Review recommended."
        }

        // NEN 4001 & NEN 1838 recommendations
        recommendations.append("Per NEN 4001: Ensure fire extinguishers within 20m walking distance, mounted at 0.8-1.2m height")
        recommendations.append("Per NEN 1838: Verify emergency exit signs are illuminated and visible from all positions")
        recommendations.append("Ensure fire extinguishers are accessible, serviced, and properly signed")

        return InspectionResult(
            id: UUID(),
            timestamp: Date(),
            image: image,
            overallRisk: overallRisk,
            hazards: hazards,
            safetyCompliance: SafetyCompliance(),
            summary: summary,
            recommendations: recommendations,
            source: .localVision
        )
    }
}

// MARK: - Response Models for Orq.ai API Parsing

private struct OrqAnalysisResponse: Codable {
    let header: OrqHeader
    let summary: String
    let safety_compliance: OrqSafetyCompliance
    let identified_hazards: [OrqHazard]
    let recommendations: [String]
}

private struct OrqHeader: Codable {
    let title: String?
    let company: String?
    let location: String?
    let date: String?
    let risk_level: String
}

/// Safety compliance item with status and label
private struct OrqComplianceItem: Codable {
    let status: Bool
    let label: String?
}

private struct OrqSafetyCompliance: Codable {
    let fire_extinguisher_visible: OrqComplianceItemOrBool
    let exit_signs_visible: OrqComplianceItemOrBool
    let clear_egress_path: OrqComplianceItemOrBool
    let electrical_hazards_present: OrqComplianceItemOrBool
    let flammable_materials_stored_properly: OrqComplianceItemOrBool
}

/// Wrapper to handle both Bool and {status, label} formats
private enum OrqComplianceItemOrBool: Codable {
    case bool(Bool)
    case item(OrqComplianceItem)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let item = try? container.decode(OrqComplianceItem.self) {
            self = .item(item)
        } else {
            self = .bool(false)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value):
            try container.encode(value)
        case .item(let item):
            try container.encode(item)
        }
    }

    var status: Bool {
        switch self {
        case .bool(let value): return value
        case .item(let item): return item.status
        }
    }
}

private struct OrqHazard: Codable {
    let title: String
    let description: String
    let recommended_action: String
    // Support both "risk_level" and "risk_rating" field names
    let risk_level: String?
    let risk_rating: String?
    let standard_reference: String?
    let image_ids: [String]?

    /// Get the risk value from either field
    var riskValue: String {
        risk_level ?? risk_rating ?? "Medium"
    }
}

// MARK: - Errors

enum AnalysisError: Error, LocalizedError {
    case imageConversionFailed
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parsingFailed
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image for analysis"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .parsingFailed:
            return "Failed to parse analysis results"
        case .noAPIKey:
            return "No API key configured"
        }
    }
}
