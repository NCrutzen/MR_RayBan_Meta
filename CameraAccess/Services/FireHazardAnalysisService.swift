/*
 * FireHazardAnalysisService.swift
 *
 * Service for analyzing photos using Orq.ai for fire safety hazard detection.
 */

import Foundation
import UIKit

// MARK: - Models

struct AnalysisResult: Identifiable {
    let id = UUID()
    let riskLevel: String
    let summary: String
    let hazards: [String]
    let recommendations: [String]
    let complianceItems: [ComplianceItem]
    let timestamp: Date
    let photo: UIImage

    struct ComplianceItem: Identifiable {
        let id = UUID()
        let item: String
        let status: Bool
    }
}

// MARK: - Service

@MainActor
class FireHazardAnalysisService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisResult: AnalysisResult?
    @Published var errorMessage: String?

    private var apiKey: String
    private var deploymentKey: String
    private let baseURL = "https://my.orq.ai/v2/deployments/invoke"

    init() {
        // Load API key from environment or Info.plist
        // Check environment first, then Info.plist
        let envKey = ProcessInfo.processInfo.environment["ORQ_API_KEY"] ?? ""
        let plistKey = Bundle.main.object(forInfoDictionaryKey: "ORQ_API_KEY") as? String ?? ""

        // Use environment if available, otherwise plist (but filter out unresolved variables)
        if !envKey.isEmpty {
            self.apiKey = envKey
        } else if !plistKey.isEmpty && !plistKey.hasPrefix("$(") {
            self.apiKey = plistKey
        } else {
            self.apiKey = ""
        }

        let envDeployment = ProcessInfo.processInfo.environment["ORQ_DEPLOYMENT_KEY"] ?? ""
        let plistDeployment = Bundle.main.object(forInfoDictionaryKey: "ORQ_DEPLOYMENT_KEY") as? String ?? ""

        if !envDeployment.isEmpty {
            self.deploymentKey = envDeployment
        } else if !plistDeployment.isEmpty && !plistDeployment.hasPrefix("$(") {
            self.deploymentKey = plistDeployment
        } else {
            self.deploymentKey = "Fire_Safety_Analyses"
        }

        // Debug output
        print("🔑 Orq.ai API Key configured: \(!apiKey.isEmpty)")
        print("📦 Orq.ai Deployment Key: \(deploymentKey)")
    }

    // Allow setting API key directly (for testing)
    func configure(apiKey: String, deploymentKey: String? = nil) {
        self.apiKey = apiKey
        if let deployment = deploymentKey {
            self.deploymentKey = deployment
        }
        print("🔑 Orq.ai reconfigured - API Key set: \(!apiKey.isEmpty)")
    }

    func analyzePhoto(_ image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil

        print("📸 Starting photo analysis...")
        print("🔑 API Key present: \(!apiKey.isEmpty)")

        do {
            // Convert image to base64
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw AnalysisError.imageConversionFailed
            }
            let base64Image = imageData.base64EncodedString()
            print("📷 Image converted to base64 (\(base64Image.count) chars)")

            // Prepare the request
            let result = try await sendAnalysisRequest(base64Image: base64Image)
            print("✅ Analysis successful!")

            self.analysisResult = AnalysisResult(
                riskLevel: result.riskLevel,
                summary: result.summary,
                hazards: result.hazards,
                recommendations: result.recommendations,
                complianceItems: result.complianceItems.map {
                    AnalysisResult.ComplianceItem(item: $0.item, status: $0.status)
                },
                timestamp: Date(),
                photo: image
            )
        } catch {
            print("❌ Analysis failed: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription

            // Fallback to local analysis if API fails - but show error in summary
            self.analysisResult = performLocalAnalysis(image, error: error.localizedDescription)
        }

        isAnalyzing = false
    }

    private func sendAnalysisRequest(base64Image: String) async throws -> OrqResponse {
        guard !apiKey.isEmpty else {
            throw AnalysisError.missingAPIKey
        }

        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Debug: show first 15 chars of API key
        let keyPreview = String(apiKey.prefix(15))
        print("🔐 API Key starts with: \(keyPreview)...")
        print("🔐 API Key length: \(apiKey.count) characters")

        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Orq.ai deployment invoke format
        let payload: [String: Any] = [
            "key": deploymentKey,
            "context": [
                "environments": [] as [String]
            ],
            "inputs": [
                "image": "data:image/jpeg;base64,\(base64Image)"
            ],
            "metadata": [:] as [String: Any]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        print("🌐 Sending request to: \(url)")
        print("📦 Deployment key: \(deploymentKey)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnalysisError.apiError
        }

        print("📡 HTTP Status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            print("❌ API Error Response: \(responseBody)")
            throw AnalysisError.httpError(statusCode: httpResponse.statusCode, message: responseBody)
        }

        let responseBody = String(data: data, encoding: .utf8) ?? ""
        print("✅ Response received: \(responseBody.prefix(500))...")

        return try parseResponse(data)
    }

    private func parseResponse(_ data: Data) throws -> OrqResponse {
        // Parse the Orq.ai response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AnalysisError.parseError
        }

        // Extract JSON from the response content
        guard let jsonStart = content.firstIndex(of: "{"),
              let jsonEnd = content.lastIndex(of: "}") else {
            throw AnalysisError.parseError
        }

        let jsonString = String(content[jsonStart...jsonEnd])
        guard let jsonData = jsonString.data(using: .utf8),
              let result = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw AnalysisError.parseError
        }

        return OrqResponse(
            riskLevel: result["risk_level"] as? String ?? "unknown",
            summary: result["summary"] as? String ?? "Analysis completed",
            hazards: result["hazards"] as? [String] ?? [],
            recommendations: result["recommendations"] as? [String] ?? [],
            complianceItems: parseComplianceItems(result["compliance"])
        )
    }

    private func parseComplianceItems(_ compliance: Any?) -> [OrqComplianceItem] {
        guard let items = compliance as? [[String: Any]] else { return [] }
        return items.compactMap { item in
            guard let name = item["item"] as? String,
                  let status = item["status"] as? Bool else { return nil }
            return OrqComplianceItem(item: name, status: status)
        }
    }

    private func performLocalAnalysis(_ image: UIImage, error: String? = nil) -> AnalysisResult {
        // Fallback local analysis when API is unavailable
        let errorInfo = error ?? "Onbekende fout"
        return AnalysisResult(
            riskLevel: "unknown",
            summary: "⚠️ API Fout: \(errorInfo)\n\nControleer handmatig op brandveiligheid.",
            hazards: ["API niet beschikbaar - handmatige inspectie vereist"],
            recommendations: [
                "Configureer je Orq.ai API key in Info.plist",
                "Controleer of je deployment ID correct is",
                "Controleer je internetverbinding",
                "Zie Xcode console voor debug info"
            ],
            complianceItems: [
                AnalysisResult.ComplianceItem(item: "API configuratie", status: false),
                AnalysisResult.ComplianceItem(item: "Handmatige controle vereist", status: false)
            ],
            timestamp: Date(),
            photo: image
        )
    }

    func clearResult() {
        analysisResult = nil
        errorMessage = nil
    }
}

// MARK: - Response Models

private struct OrqResponse {
    let riskLevel: String
    let summary: String
    let hazards: [String]
    let recommendations: [String]
    let complianceItems: [OrqComplianceItem]
}

private struct OrqComplianceItem {
    let item: String
    let status: Bool
}

// MARK: - Errors

enum AnalysisError: LocalizedError {
    case imageConversionFailed
    case missingAPIKey
    case apiError
    case httpError(statusCode: Int, message: String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Kon foto niet verwerken"
        case .missingAPIKey:
            return "API key niet geconfigureerd"
        case .apiError:
            return "Fout bij communicatie met analyse service"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message.prefix(200))"
        case .parseError:
            return "Kon analyse resultaat niet verwerken"
        }
    }
}
