import Foundation
import CloudKit

/// Service category enumeration with Springer's departmental classifications
enum ServiceCategory: String, CaseIterable, Codable, Sendable {
    case jewelryRepair = "JR"           // Jewelry Repair - primary client repairs
    case watchService = "WS"            // Watch Service - watch repairs and maintenance
    case carePlan = "BC"                // Care Plan - maintenance and cleaning services
    case estateLiquidation = "LIQ"      // Estate Pre-Stock - lower priority unless time-sensitive
    case appraisal = "APPRAISAL"        // Appraisal services
    case cleaning = "CLEANING"          // Cleaning and inspection
    case customDesign = "CUSTOM_DESIGN" // Custom design services
    case engraving = "ENGRAVING"        // Engraving services
    case other = "OTHER"                // Other miscellaneous services
    
    /// User-friendly display name for the category
    var displayName: String {
        switch self {
        case .jewelryRepair: return "Jewelry Repair (JR)"
        case .watchService: return "Watch Service (WS)"
        case .carePlan: return "Care Plan (BC)"
        case .estateLiquidation: return "Estate Liquidation (LIQ)"
        case .appraisal: return "Appraisal"
        case .cleaning: return "Cleaning & Inspection"
        case .customDesign: return "Custom Design"
        case .engraving: return "Engraving"
        case .other: return "Other"
        }
    }
    
    /// Priority level for queue management
    var priority: Int {
        switch self {
        case .jewelryRepair, .watchService: return 1  // Highest priority - client repairs
        case .carePlan, .appraisal, .cleaning: return 2  // Medium priority
        case .customDesign, .engraving: return 3  // Lower priority
        case .estateLiquidation, .other: return 4  // Lowest priority unless flagged
        }
    }
    
    /// Whether this category supports rush services
    var supportsRush: Bool {
        switch self {
        case .jewelryRepair, .watchService, .cleaning: return true
        case .carePlan, .appraisal, .customDesign: return true
        case .engraving: return false  // Engraving typically cannot be rushed
        case .estateLiquidation, .other: return false
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
    
    // Springer's specific enhancements
    let isGenericSku: Bool                    // Whether this uses generic pricing (e.g., 14JR0001)
    let requiresSpringersCheck: Bool          // Whether to check if item was purchased at Springer's
    let metalTypes: [MetalType]               // Supported metal types for this service
    let sizingCategory: SizingCategory?       // For ring sizing services
    let watchBrand: String?                   // For brand-specific watch services
    let estimateRequired: Bool                // Whether estimate is required before work
    let vendorService: Bool                   // Whether this service is performed by vendor
    let qualityControlRequired: Bool          // Whether QC inspection is required
    
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
        isActive: Bool = true,
        isGenericSku: Bool = false,
        requiresSpringersCheck: Bool = false,
        metalTypes: [MetalType] = [],
        sizingCategory: SizingCategory? = nil,
        watchBrand: String? = nil,
        estimateRequired: Bool = false,
        vendorService: Bool = false,
        qualityControlRequired: Bool = true
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
        self.isGenericSku = isGenericSku
        self.requiresSpringersCheck = requiresSpringersCheck
        self.metalTypes = metalTypes
        self.sizingCategory = sizingCategory
        self.watchBrand = watchBrand
        self.estimateRequired = estimateRequired
        self.vendorService = vendorService
        self.qualityControlRequired = qualityControlRequired
    }
    
    /// Whether this service type typically involves metal work
    var involvesMetal: Bool {
        defaultMetalUsageGrams != nil && (defaultMetalUsageGrams ?? 0) > 0
    }
    
    /// Whether this service supports rush timing
    var supportsRush: Bool {
        category.supportsRush && !vendorService // Vendor services typically can't be rushed
    }
}

/// Ring sizing category for specific pricing
enum SizingCategory: String, CaseIterable, Codable, Sendable {
    case under3mm = "UNDER_3MM"
    case mm3to5 = "3_TO_5_MM"
    case mm5to8 = "5_TO_8_MM"
    case over8mm = "OVER_8MM"
    
    var displayName: String {
        switch self {
        case .under3mm: return "Under 3mm"
        case .mm3to5: return "3-5mm"
        case .mm5to8: return "5-8mm"
        case .over8mm: return "Over 8mm"
        }
    }
}

// MARK: - CloudKit Record Type
extension ServiceType {
    static let recordType = "ServiceType"
}
