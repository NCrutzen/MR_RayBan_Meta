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

    private let apiKey: String
    private let deploymentId: String
    private let baseURL = "https://api.orq.ai/v2/deployments"

    init() {
        // Load API key from environment or Info.plist
        self.apiKey = ProcessInfo.processInfo.environment["ORQ_API_KEY"]
            ?? Bundle.main.object(forInfoDictionaryKey: "ORQ_API_KEY") as? String
            ?? ""
        self.deploymentId = ProcessInfo.processInfo.environment["ORQ_DEPLOYMENT_ID"]
            ?? Bundle.main.object(forInfoDictionaryKey: "ORQ_DEPLOYMENT_ID") as? String
            ?? "fire-safety-analysis"
    }

    func analyzePhoto(_ image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil

        do {
            // Convert image to base64
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw AnalysisError.imageConversionFailed
            }
            let base64Image = imageData.base64EncodedString()

            // Prepare the request
            let result = try await sendAnalysisRequest(base64Image: base64Image)
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
            self.errorMessage = error.localizedDescription

            // Fallback to local analysis if API fails
            self.analysisResult = performLocalAnalysis(image)
        }

        isAnalyzing = false
    }

    private func sendAnalysisRequest(base64Image: String) async throws -> OrqResponse {
        guard !apiKey.isEmpty else {
            throw AnalysisError.missingAPIKey
        }

        let url = URL(string: "\(baseURL)/\(deploymentId)/invoke")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ],
                        [
                            "type": "text",
                            "text": """
                            Analyze this image for fire safety hazards. Provide your response in the following JSON format:
                            {
                                "risk_level": "low|medium|high|critical",
                                "summary": "Brief summary of findings",
                                "hazards": ["list", "of", "identified", "hazards"],
                                "recommendations": ["list", "of", "recommendations"],
                                "compliance": [
                                    {"item": "Fire extinguisher present", "status": true/false},
                                    {"item": "Emergency exits clear", "status": true/false},
                                    {"item": "Electrical hazards", "status": true/false},
                                    {"item": "Flammable materials stored safely", "status": true/false}
                                ]
                            }
                            """
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AnalysisError.apiError
        }

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

    private func performLocalAnalysis(_ image: UIImage) -> AnalysisResult {
        // Fallback local analysis when API is unavailable
        return AnalysisResult(
            riskLevel: "unknown",
            summary: "Automatische analyse niet beschikbaar. Controleer handmatig op brandveiligheid.",
            hazards: ["Handmatige inspectie vereist"],
            recommendations: [
                "Controleer op zichtbare brandgevaren",
                "Verifieer aanwezigheid brandblusser",
                "Controleer nooduitgangen",
                "Inspecteer elektrische installaties"
            ],
            complianceItems: [
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
    case parseError

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Kon foto niet verwerken"
        case .missingAPIKey:
            return "API key niet geconfigureerd"
        case .apiError:
            return "Fout bij communicatie met analyse service"
        case .parseError:
            return "Kon analyse resultaat niet verwerken"
        }
    }
}
