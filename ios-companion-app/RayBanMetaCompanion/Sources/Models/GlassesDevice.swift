import Foundation

/// Represents a Ray-Ban Meta glasses device
struct GlassesDevice: Identifiable, Codable {
    let id: String
    let name: String
    let model: GlassesModel
    var firmwareVersion: String?
    var batteryLevel: Int?
    var lastConnected: Date?
    var isConnected: Bool

    enum GlassesModel: String, Codable, CaseIterable {
        case wayfarerGen2 = "Wayfarer Gen 2"
        case wayfarerLargeGen2 = "Wayfarer Large Gen 2"
        case headlinerGen2 = "Headliner Gen 2"
        case skylerGen2 = "Skyler Gen 2"
        case unknown = "Unknown Model"

        var displayName: String { rawValue }

        var features: [String] {
            switch self {
            case .wayfarerGen2, .wayfarerLargeGen2:
                return ["12MP Camera", "Meta AI", "5-mic Array", "Open-ear Speakers"]
            case .headlinerGen2:
                return ["12MP Camera", "Meta AI", "5-mic Array", "Open-ear Speakers"]
            case .skylerGen2:
                return ["12MP Camera", "Meta AI", "5-mic Array", "Open-ear Speakers"]
            case .unknown:
                return []
            }
        }
    }

    init(id: String = UUID().uuidString,
         name: String = "Ray-Ban Meta",
         model: GlassesModel = .wayfarerGen2) {
        self.id = id
        self.name = name
        self.model = model
        self.isConnected = false
    }
}

// MARK: - Battery Status

extension GlassesDevice {
    var batteryStatus: BatteryStatus {
        guard let level = batteryLevel else { return .unknown }

        switch level {
        case 0..<20:
            return .critical
        case 20..<40:
            return .low
        case 40..<80:
            return .medium
        case 80...100:
            return .high
        default:
            return .unknown
        }
    }

    enum BatteryStatus {
        case critical
        case low
        case medium
        case high
        case unknown

        var iconName: String {
            switch self {
            case .critical: return "battery.0"
            case .low: return "battery.25"
            case .medium: return "battery.50"
            case .high: return "battery.100"
            case .unknown: return "battery.0"
            }
        }

        var color: String {
            switch self {
            case .critical: return "red"
            case .low: return "orange"
            case .medium, .high: return "green"
            case .unknown: return "gray"
            }
        }
    }
}
