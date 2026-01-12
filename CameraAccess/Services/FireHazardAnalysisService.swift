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
    let header: Header
    let summary: String
    let safetyCompliance: [ComplianceItem]
    let identifiedHazards: [Hazard]
    let recommendations: [String]
    let footer: Footer
    let timestamp: Date
    let photo: UIImage

    struct Header {
        let title: String
        let company: String
        let location: String
        let date: String
        let riskLevel: String
    }

    struct ComplianceItem: Identifiable {
        let id = UUID()
        let key: String
        let label: String
        let status: Bool
    }

    struct Hazard: Identifiable {
        let id = UUID()
        let title: String
        let riskLevel: String
        let description: String
        let recommendedAction: String
    }

    struct Footer {
        let generatedBy: String
        let analyzedBy: String
        let links: [String]
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
        let envKey = ProcessInfo.processInfo.environment["ORQ_API_KEY"] ?? ""
        let plistKey = Bundle.main.object(forInfoDictionaryKey: "ORQ_API_KEY") as? String ?? ""

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

        print("🔑 Orq.ai API Key configured: \(!apiKey.isEmpty)")
        print("📦 Orq.ai Deployment Key: \(deploymentKey)")
    }

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
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw AnalysisError.imageConversionFailed
            }
            let base64Image = imageData.base64EncodedString()
            print("📷 Image converted to base64 (\(base64Image.count) chars)")

            let result = try await sendAnalysisRequest(base64Image: base64Image)
            print("✅ Analysis successful!")

            self.analysisResult = AnalysisResult(
                header: AnalysisResult.Header(
                    title: result.header.title,
                    company: result.header.company,
                    location: result.header.location,
                    date: result.header.date,
                    riskLevel: result.header.riskLevel
                ),
                summary: result.summary,
                safetyCompliance: result.safetyCompliance.map {
                    AnalysisResult.ComplianceItem(key: $0.key, label: $0.label, status: $0.status)
                },
                identifiedHazards: result.identifiedHazards.map {
                    AnalysisResult.Hazard(
                        title: $0.title,
                        riskLevel: $0.riskLevel,
                        description: $0.description,
                        recommendedAction: $0.recommendedAction
                    )
                },
                recommendations: result.recommendations,
                footer: AnalysisResult.Footer(
                    generatedBy: result.footer.generatedBy,
                    analyzedBy: result.footer.analyzedBy,
                    links: result.footer.links
                ),
                timestamp: Date(),
                photo: image
            )
        } catch {
            print("❌ Analysis failed: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
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

        let keyPreview = String(apiKey.prefix(15))
        print("🔐 API Key starts with: \(keyPreview)...")
        print("🔐 API Key length: \(apiKey.count) characters")

        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

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
        // Parse the Orq.ai response wrapper
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

        // Parse header
        let headerDict = result["header"] as? [String: Any] ?? [:]
        let header = OrqHeader(
            title: headerDict["title"] as? String ?? "FIRE HAZARD INSPECTION REPORT",
            company: headerDict["company"] as? String ?? "Smeba Fire Safety | Moyne Roberts",
            location: headerDict["location"] as? String ?? "Unknown",
            date: headerDict["date"] as? String ?? "",
            riskLevel: headerDict["risk_level"] as? String ?? "Unknown"
        )

        // Parse summary
        let summary = result["summary"] as? String ?? "Analysis completed"

        // Parse safety compliance
        var safetyCompliance: [OrqComplianceItem] = []
        if let complianceDict = result["safety_compliance"] as? [String: [String: Any]] {
            for (key, value) in complianceDict {
                let status = value["status"] as? Bool ?? false
                let label = value["label"] as? String ?? key
                safetyCompliance.append(OrqComplianceItem(key: key, label: label, status: status))
            }
        }

        // Parse identified hazards
        var identifiedHazards: [OrqHazard] = []
        if let hazardsArray = result["identified_hazards"] as? [[String: Any]] {
            for hazard in hazardsArray {
                identifiedHazards.append(OrqHazard(
                    title: hazard["title"] as? String ?? "Unknown Hazard",
                    riskLevel: hazard["risk_level"] as? String ?? "Unknown",
                    description: hazard["description"] as? String ?? "",
                    recommendedAction: hazard["recommended_action"] as? String ?? ""
                ))
            }
        }

        // Parse recommendations
        let recommendations = result["recommendations"] as? [String] ?? []

        // Parse footer
        let footerDict = result["footer"] as? [String: Any] ?? [:]
        let footer = OrqFooter(
            generatedBy: footerDict["generated_by"] as? String ?? "MR Smart Glasses App",
            analyzedBy: footerDict["analyzed_by"] as? String ?? "Claude AI",
            links: footerDict["links"] as? [String] ?? []
        )

        return OrqResponse(
            header: header,
            summary: summary,
            safetyCompliance: safetyCompliance,
            identifiedHazards: identifiedHazards,
            recommendations: recommendations,
            footer: footer
        )
    }

    private func performLocalAnalysis(_ image: UIImage, error: String? = nil) -> AnalysisResult {
        let errorInfo = error ?? "Unknown error"
        return AnalysisResult(
            header: AnalysisResult.Header(
                title: "FIRE HAZARD INSPECTION REPORT",
                company: "Smeba Fire Safety | Moyne Roberts",
                location: "Unknown",
                date: "",
                riskLevel: "Unknown"
            ),
            summary: "⚠️ API Error: \(errorInfo)\n\nManual inspection required.",
            safetyCompliance: [
                AnalysisResult.ComplianceItem(key: "api_config", label: "API Configuration", status: false),
                AnalysisResult.ComplianceItem(key: "manual_check", label: "Manual Check Required", status: false)
            ],
            identifiedHazards: [
                AnalysisResult.Hazard(
                    title: "API Not Available",
                    riskLevel: "Unknown",
                    description: "Could not connect to analysis service.",
                    recommendedAction: "Check API configuration and internet connection."
                )
            ],
            recommendations: [
                "Configure your Orq.ai API key in Info.plist",
                "Verify the deployment key is correct",
                "Check your internet connection",
                "See Xcode console for debug info"
            ],
            footer: AnalysisResult.Footer(
                generatedBy: "MR Smart Glasses App",
                analyzedBy: "Local Fallback",
                links: ["www.smeba.nl", "www.moyneroberts.ie"]
            ),
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
    let header: OrqHeader
    let summary: String
    let safetyCompliance: [OrqComplianceItem]
    let identifiedHazards: [OrqHazard]
    let recommendations: [String]
    let footer: OrqFooter
}

private struct OrqHeader {
    let title: String
    let company: String
    let location: String
    let date: String
    let riskLevel: String
}

private struct OrqComplianceItem {
    let key: String
    let label: String
    let status: Bool
}

private struct OrqHazard {
    let title: String
    let riskLevel: String
    let description: String
    let recommendedAction: String
}

private struct OrqFooter {
    let generatedBy: String
    let analyzedBy: String
    let links: [String]
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
            return "Could not process image"
        case .missingAPIKey:
            return "API key not configured"
        case .apiError:
            return "Error communicating with analysis service"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message.prefix(200))"
        case .parseError:
            return "Could not parse analysis result"
        }
    }
}
