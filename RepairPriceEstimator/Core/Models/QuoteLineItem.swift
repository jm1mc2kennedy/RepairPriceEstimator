import Foundation
import CloudKit

/// Metal type enumeration for jewelry repair work
enum MetalType: String, CaseIterable, Codable, Sendable, Identifiable {
    var id: String { rawValue }
    case gold14K = "GOLD_14K"
    case gold18K = "GOLD_18K"
    case gold22K = "GOLD_22K"
    case platinum = "PLATINUM"
    case palladium = "PALLADIUM"
    case silver = "SILVER"
    case stainlessSteel = "STAINLESS_STEEL"
    case titanium = "TITANIUM"
    case other = "OTHER"
    
    /// User-friendly display name for the metal type
    var displayName: String {
        switch self {
        case .gold14K: return "14K Gold"
        case .gold18K: return "18K Gold"
        case .gold22K: return "22K Gold"
        case .platinum: return "Platinum"
        case .palladium: return "Palladium"
        case .silver: return "Silver"
        case .stainlessSteel: return "Stainless Steel"
        case .titanium: return "Titanium"
        case .other: return "Other"
        }
    }
    
    /// Whether this metal type requires market rate pricing
    var requiresMarketRatePricing: Bool {
        switch self {
        case .gold14K, .gold18K, .gold22K, .platinum, .palladium, .silver:
            return true
        case .stainlessSteel, .titanium, .other:
            return false
        }
    }
}

/// Represents a line item within a repair quote
struct QuoteLineItem: Identifiable, Codable, Sendable {
    let id: String
    let quoteId: String
    let serviceTypeId: String
    let sku: String
    let description: String
    let metalType: MetalType?
    let metalWeightGrams: Decimal?
    let laborMinutes: Int
    let baseCost: Decimal
    let baseRetail: Decimal
    var calculatedRetail: Decimal
    var manualOverrideRetail: Decimal?
    var overrideReason: String?
    let isRush: Bool
    let rushMultiplier: Decimal
    var finalRetail: Decimal
    
    init(
        id: String = UUID().uuidString,
        quoteId: String,
        serviceTypeId: String,
        sku: String,
        description: String,
        metalType: MetalType? = nil,
        metalWeightGrams: Decimal? = nil,
        laborMinutes: Int,
        baseCost: Decimal,
        baseRetail: Decimal,
        calculatedRetail: Decimal,
        manualOverrideRetail: Decimal? = nil,
        overrideReason: String? = nil,
        isRush: Bool = false,
        rushMultiplier: Decimal = 1.0,
        finalRetail: Decimal? = nil
    ) {
        self.id = id
        self.quoteId = quoteId
        self.serviceTypeId = serviceTypeId
        self.sku = sku
        self.description = description
        self.metalType = metalType
        self.metalWeightGrams = metalWeightGrams
        self.laborMinutes = laborMinutes
        self.baseCost = baseCost
        self.baseRetail = baseRetail
        self.calculatedRetail = calculatedRetail
        self.manualOverrideRetail = manualOverrideRetail
        self.overrideReason = overrideReason
        self.isRush = isRush
        self.rushMultiplier = isRush ? 1.5 : 1.0
        self.finalRetail = finalRetail ?? (manualOverrideRetail ?? calculatedRetail)
    }
    
    /// Whether this line item has a manual override applied
    var hasOverride: Bool {
        manualOverrideRetail != nil
    }
    
    /// The price that will be charged to the customer
    var effectiveRetail: Decimal {
        manualOverrideRetail ?? calculatedRetail
    }
}

// MARK: - CloudKit Record Type
extension QuoteLineItem {
    static let recordType = "QuoteLineItem"
}
