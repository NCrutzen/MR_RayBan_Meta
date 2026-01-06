import Foundation

// MARK: - N-XT API Response Models

/// Root response wrapper - the API returns { d: Job }
struct JobResponse: Codable {
    let d: Job
}

/// Job details from N-XT API
struct Job: Codable, Identifiable {
    let id: String?
    let jobNumber: String?
    let description: String?
    let status: String?
    let scheduledDate: String?
    let completedDate: String?
    let site: Site?
    let customer: Customer?
    let technician: Technician?

    enum CodingKeys: String, CodingKey {
        case id
        case jobNumber = "job_number"
        case description
        case status
        case scheduledDate = "scheduled_date"
        case completedDate = "completed_date"
        case site
        case customer
        case technician
    }
}

/// Site information containing assets
struct Site: Codable {
    let id: String?
    let name: String?
    let address: String?
    let city: String?
    let postcode: String?
    let assets: [JobAsset]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case city
        case postcode
        case assets
    }
}

/// Customer information
struct Customer: Codable {
    let id: String?
    let name: String?
    let email: String?
    let phone: String?
}

/// Technician information
struct Technician: Codable {
    let id: String?
    let name: String?
    let email: String?
}

/// Asset from N-XT API - located in d.site.assets
struct JobAsset: Codable, Identifiable {
    let id: String
    let serialNumber: String?
    let barcode: String?
    let assetType: String?
    let description: String?
    let manufacturer: String?
    let model: String?
    let location: String?
    let floor: String?
    let room: String?
    let status: String?
    let lastServiceDate: String?
    let nextServiceDate: String?
    let installDate: String?
    let expiryDate: String?
    let capacity: String?
    let rating: String?
    let notes: String?
    let inspectionItems: [InspectionItem]?

    enum CodingKeys: String, CodingKey {
        case id
        case serialNumber = "serial_number"
        case barcode
        case assetType = "asset_type"
        case description
        case manufacturer
        case model
        case location
        case floor
        case room
        case status
        case lastServiceDate = "last_service_date"
        case nextServiceDate = "next_service_date"
        case installDate = "install_date"
        case expiryDate = "expiry_date"
        case capacity
        case rating
        case notes
        case inspectionItems = "inspection_items"
    }
}

/// Inspection checklist item
struct InspectionItem: Codable, Identifiable {
    let id: String?
    let name: String?
    let result: String?
    let notes: String?
    let required: Bool?

    var identifier: String {
        id ?? UUID().uuidString
    }
}

// MARK: - JobAsset Extensions

extension JobAsset {
    /// Display name for the asset type
    var displayType: String {
        assetType ?? "Unknown Asset"
    }

    /// Icon name for the asset type
    var iconName: String {
        guard let type = assetType?.lowercased() else { return "wrench.and.screwdriver.fill" }

        if type.contains("extinguisher") { return "flame.fill" }
        if type.contains("alarm") || type.contains("detector") { return "bell.fill" }
        if type.contains("smoke") { return "sensor.fill" }
        if type.contains("sprinkler") { return "drop.fill" }
        if type.contains("light") || type.contains("emergency") { return "lightbulb.fill" }
        if type.contains("blanket") { return "rectangle.fill" }
        if type.contains("hose") { return "circle.circle.fill" }
        if type.contains("door") { return "door.left.hand.closed" }
        if type.contains("exit") || type.contains("sign") { return "arrow.right.square.fill" }
        if type.contains("first") || type.contains("aid") { return "cross.case.fill" }

        return "wrench.and.screwdriver.fill"
    }

    /// Status color
    var statusColor: String {
        guard let status = status?.lowercased() else { return "#6B7280" }

        if status.contains("pass") || status.contains("ok") || status.contains("active") {
            return "#22C55E"
        }
        if status.contains("fail") || status.contains("fault") {
            return "#EF4444"
        }
        if status.contains("due") || status.contains("warning") || status.contains("attention") {
            return "#F59E0B"
        }
        if status.contains("maintenance") || status.contains("service") {
            return "#3B82F6"
        }

        return "#6B7280"
    }

    /// Formatted location string
    var formattedLocation: String {
        var parts: [String] = []
        if let loc = location, !loc.isEmpty { parts.append(loc) }
        if let fl = floor, !fl.isEmpty { parts.append("Floor \(fl)") }
        if let rm = room, !rm.isEmpty { parts.append(rm) }
        return parts.isEmpty ? "Location not specified" : parts.joined(separator: ", ")
    }

    /// Check if service is overdue
    var isServiceOverdue: Bool {
        guard let nextDateString = nextServiceDate else { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let nextDate = formatter.date(from: nextDateString) else { return false }
        return nextDate < Date()
    }

    /// Formatted last service date
    var formattedLastService: String {
        guard let dateString = lastServiceDate else { return "Never" }
        return formatDateString(dateString)
    }

    /// Formatted next service date
    var formattedNextService: String {
        guard let dateString = nextServiceDate else { return "Not scheduled" }
        return formatDateString(dateString)
    }

    /// Formatted expiry date
    var formattedExpiry: String? {
        guard let dateString = expiryDate else { return nil }
        return formatDateString(dateString)
    }

    private func formatDateString(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate]

        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }

        // Try alternative format
        let altFormatter = DateFormatter()
        altFormatter.dateFormat = "yyyy-MM-dd"
        if let date = altFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }

        return dateString
    }
}

// MARK: - Job Extensions

extension Job {
    var displayStatus: String {
        status?.capitalized ?? "Unknown"
    }

    var assetCount: Int {
        site?.assets?.count ?? 0
    }

    var formattedScheduledDate: String? {
        guard let dateString = scheduledDate else { return nil }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Mock Data

extension JobAsset {
    static let mockFireExtinguisher = JobAsset(
        id: "asset-001",
        serialNumber: "MR-FE-78542",
        barcode: "5012345678901",
        assetType: "Fire Extinguisher",
        description: "6kg ABC Powder Fire Extinguisher",
        manufacturer: "Gloria",
        model: "PDE 6 GA",
        location: "Main Office",
        floor: "2",
        room: "Reception",
        status: "Pass",
        lastServiceDate: "2024-09-15",
        nextServiceDate: "2025-09-15",
        installDate: "2022-03-10",
        expiryDate: "2027-03-10",
        capacity: "6 kg",
        rating: "34A 183B C",
        notes: "Near main entrance",
        inspectionItems: [
            InspectionItem(id: "1", name: "Pressure Gauge", result: "OK", notes: nil, required: true),
            InspectionItem(id: "2", name: "Safety Pin", result: "OK", notes: nil, required: true),
            InspectionItem(id: "3", name: "Hose Condition", result: "OK", notes: nil, required: true)
        ]
    )
}

extension Job {
    static let mock = Job(
        id: "1563748",
        jobNumber: "JOB-2024-1563748",
        description: "Annual Fire Safety Inspection",
        status: "In Progress",
        scheduledDate: "2024-12-23T09:00:00Z",
        completedDate: nil,
        site: Site(
            id: "site-001",
            name: "Moyne Roberts HQ",
            address: "123 Fire Safety Street",
            city: "Dublin",
            postcode: "D01 AB12",
            assets: [JobAsset.mockFireExtinguisher]
        ),
        customer: Customer(
            id: "cust-001",
            name: "Moyne Roberts Ltd",
            email: "info@moyneroberts.ie",
            phone: "+353 1 234 5678"
        ),
        technician: Technician(
            id: "tech-001",
            name: "John Smith",
            email: "john.smith@moyneroberts.ie"
        )
    )
}

// MARK: - Legacy Asset Model (keeping for backwards compatibility)

struct Asset: Identifiable, Codable {
    let id: String
    let serialNumber: String
    let type: AssetType
    let manufacturer: String?
    let model: String?
    let location: AssetLocation?
    let status: AssetStatus
    let lastInspectionDate: Date?
    let nextInspectionDue: Date?
    let installationDate: Date?
    let maintenanceHistory: [MaintenanceRecord]?
    let specifications: [String: String]?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case serialNumber = "serial_number"
        case type
        case manufacturer
        case model
        case location
        case status
        case lastInspectionDate = "last_inspection_date"
        case nextInspectionDue = "next_inspection_due"
        case installationDate = "installation_date"
        case maintenanceHistory = "maintenance_history"
        case specifications
        case notes
    }
}

enum AssetType: String, Codable, CaseIterable {
    case fireExtinguisher = "fire_extinguisher"
    case fireAlarm = "fire_alarm"
    case smokeDetector = "smoke_detector"
    case sprinklerSystem = "sprinkler_system"
    case emergencyLighting = "emergency_lighting"
    case fireBlanket = "fire_blanket"
    case fireHoseReel = "fire_hose_reel"
    case fireDoor = "fire_door"
    case exitSign = "exit_sign"
    case firstAidKit = "first_aid_kit"
    case other = "other"

    var displayName: String {
        switch self {
        case .fireExtinguisher: return "Fire Extinguisher"
        case .fireAlarm: return "Fire Alarm"
        case .smokeDetector: return "Smoke Detector"
        case .sprinklerSystem: return "Sprinkler System"
        case .emergencyLighting: return "Emergency Lighting"
        case .fireBlanket: return "Fire Blanket"
        case .fireHoseReel: return "Fire Hose Reel"
        case .fireDoor: return "Fire Door"
        case .exitSign: return "Exit Sign"
        case .firstAidKit: return "First Aid Kit"
        case .other: return "Other"
        }
    }
}

enum AssetStatus: String, Codable {
    case active = "active"
    case needsInspection = "needs_inspection"
    case underMaintenance = "under_maintenance"
    case faulty = "faulty"
    case retired = "retired"
}

struct AssetLocation: Codable {
    let building: String?
    let floor: String?
    let room: String?
    let description: String?
}

struct MaintenanceRecord: Identifiable, Codable {
    let id: String
    let date: Date
    let type: MaintenanceType
    let technician: String?
    let notes: String?
    let passed: Bool?
}

enum MaintenanceType: String, Codable {
    case inspection = "inspection"
    case service = "service"
    case repair = "repair"
    case replacement = "replacement"
    case installation = "installation"
}
