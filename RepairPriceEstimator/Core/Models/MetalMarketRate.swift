import Foundation
import CloudKit

/// Unit of measurement for metal pricing
enum MetalUnit: String, CaseIterable, Codable, Sendable {
    case gramsPerGram = "GRAMS_PER_GRAM"
    case ouncesPerOunce = "OUNCES_PER_OUNCE"
    case pennyweightPerPennyweight = "PENNYWEIGHT_PER_PENNYWEIGHT"
    
    /// User-friendly display name for the unit
    var displayName: String {
        switch self {
        case .gramsPerGram: return "per gram"
        case .ouncesPerOunce: return "per ounce"
        case .pennyweightPerPennyweight: return "per pennyweight"
        }
    }
    
    /// Short symbol for the unit
    var symbol: String {
        switch self {
        case .gramsPerGram: return "g"
        case .ouncesPerOunce: return "oz"
        case .pennyweightPerPennyweight: return "dwt"
        }
    }
}

/// Represents current market rates for precious metals
struct MetalMarketRate: Identifiable, Codable, Sendable {
    let id: String
    let companyId: String
    let metalType: MetalType
    let unit: MetalUnit
    let rate: Decimal
    let effectiveDate: Date
    let createdAt: Date
    let isActive: Bool
    
    init(
        id: String = UUID().uuidString,
        companyId: String,
        metalType: MetalType,
        unit: MetalUnit = .gramsPerGram,
        rate: Decimal,
        effectiveDate: Date = Date(),
        createdAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.companyId = companyId
        self.metalType = metalType
        self.unit = unit
        self.rate = rate
        self.effectiveDate = effectiveDate
        self.createdAt = createdAt
        self.isActive = isActive
    }
    
    /// Formatted display of the rate
    var formattedRate: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: rate as NSDecimalNumber) ?? "$\(rate)"
    }
    
    /// Full display string including metal type and unit
    var displayString: String {
        "\(metalType.displayName): \(formattedRate) \(unit.displayName)"
    }
}

// MARK: - CloudKit Record Type
extension MetalMarketRate {
    static let recordType = "MetalMarketRate"
}
