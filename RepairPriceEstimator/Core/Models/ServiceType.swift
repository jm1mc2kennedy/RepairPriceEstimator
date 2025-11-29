import Foundation
import CloudKit

/// Service category enumeration
enum ServiceCategory: String, CaseIterable, Codable, Sendable {
    case jewelryRepair = "JEWELRY_REPAIR"
    case watchRepair = "WATCH_REPAIR"
    case cleaning = "CLEANING"
    case appraisal = "APPRAISAL"
    case customDesign = "CUSTOM_DESIGN"
    case engraving = "ENGRAVING"
    case other = "OTHER"
    
    /// User-friendly display name for the category
    var displayName: String {
        switch self {
        case .jewelryRepair: return "Jewelry Repair"
        case .watchRepair: return "Watch Repair"
        case .cleaning: return "Cleaning"
        case .appraisal: return "Appraisal"
        case .customDesign: return "Custom Design"
        case .engraving: return "Engraving"
        case .other: return "Other"
        }
    }
}

/// Represents a type of service that can be performed
struct ServiceType: Identifiable, Codable, Sendable {
    let id: String
    let companyId: String
    let name: String
    let category: ServiceCategory
    let defaultSku: String
    let defaultLaborMinutes: Int
    let defaultMetalUsageGrams: Decimal?
    let baseRetail: Decimal
    let baseCost: Decimal
    let pricingFormulaId: String?
    let isActive: Bool
    
    init(
        id: String = UUID().uuidString,
        companyId: String,
        name: String,
        category: ServiceCategory,
        defaultSku: String,
        defaultLaborMinutes: Int,
        defaultMetalUsageGrams: Decimal? = nil,
        baseRetail: Decimal,
        baseCost: Decimal,
        pricingFormulaId: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.companyId = companyId
        self.name = name
        self.category = category
        self.defaultSku = defaultSku
        self.defaultLaborMinutes = defaultLaborMinutes
        self.defaultMetalUsageGrams = defaultMetalUsageGrams
        self.baseRetail = baseRetail
        self.baseCost = baseCost
        self.pricingFormulaId = pricingFormulaId
        self.isActive = isActive
    }
    
    /// Whether this service type typically involves metal work
    var involvesMetal: Bool {
        defaultMetalUsageGrams != nil && (defaultMetalUsageGrams ?? 0) > 0
    }
}

// MARK: - CloudKit Record Type
extension ServiceType {
    static let recordType = "ServiceType"
}
