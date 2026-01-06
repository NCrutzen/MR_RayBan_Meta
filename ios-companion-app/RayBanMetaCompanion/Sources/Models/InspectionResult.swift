import Foundation
import UIKit

/// Result of a fire hazard inspection analysis
struct InspectionResult: Identifiable {
    let id: UUID
    let timestamp: Date
    let image: UIImage
    let overallRisk: RiskLevel
    let hazards: [FireHazard]
    let safetyCompliance: SafetyCompliance
    let summary: String
    let recommendations: [String]
    let source: AnalysisSource

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var hazardCount: Int {
        hazards.count
    }

    var criticalHazardCount: Int {
        hazards.filter { $0.severity == .critical || $0.severity == .high }.count
    }
}

/// Overall risk level for the inspected area
enum RiskLevel: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case critical

    var displayName: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .low: return "10B981"      // Green
        case .medium: return "F59E0B"   // Yellow/Orange
        case .high: return "EF4444"     // Red
        case .critical: return "7C2D12" // Dark Red
        }
    }

    var iconName: String {
        switch self {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "flame.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

/// Individual fire hazard identified during inspection
struct FireHazard: Identifiable {
    let id = UUID()
    let type: String
    let description: String
    let severity: HazardSeverity
    let recommendation: String
}

/// Severity level for individual hazards
enum HazardSeverity: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case critical

    var displayName: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .low: return "10B981"
        case .medium: return "F59E0B"
        case .high: return "EF4444"
        case .critical: return "7C2D12"
        }
    }
}

/// Safety compliance checklist results
struct SafetyCompliance: Codable {
    var fireExtinguisherVisible: Bool?
    var exitSignsVisible: Bool?
    var clearEgressPath: Bool?
    var electricalHazards: Bool?
    var flammableMaterialsStored: Bool?

    init(
        fireExtinguisherVisible: Bool? = nil,
        exitSignsVisible: Bool? = nil,
        clearEgressPath: Bool? = nil,
        electricalHazards: Bool? = nil,
        flammableMaterialsStored: Bool? = nil
    ) {
        self.fireExtinguisherVisible = fireExtinguisherVisible
        self.exitSignsVisible = exitSignsVisible
        self.clearEgressPath = clearEgressPath
        self.electricalHazards = electricalHazards
        self.flammableMaterialsStored = flammableMaterialsStored
    }

    var complianceItems: [(name: String, status: Bool?, isPositive: Bool)] {
        [
            ("Fire Extinguisher Visible", fireExtinguisherVisible, true),
            ("Exit Signs Visible", exitSignsVisible, true),
            ("Clear Egress Path", clearEgressPath, true),
            ("Electrical Hazards Present", electricalHazards, false),
            ("Flammable Materials Stored Improperly", flammableMaterialsStored, false)
        ]
    }

    var passedCount: Int {
        complianceItems.filter { item in
            guard let status = item.status else { return false }
            return item.isPositive ? status : !status
        }.count
    }

    var totalChecked: Int {
        complianceItems.filter { $0.status != nil }.count
    }
}

/// Source of the analysis
enum AnalysisSource: String {
    case claudeAI = "Claude AI"
    case localVision = "Local Vision"

    var iconName: String {
        switch self {
        case .claudeAI: return "brain"
        case .localVision: return "eye"
        }
    }
}
