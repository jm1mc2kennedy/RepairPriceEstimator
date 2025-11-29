import Foundation
import CloudKit

/// Formula definition for pricing calculations
struct PricingFormula: Codable, Sendable {
    let metalMarkupPercentage: Decimal
    let laborMarkupPercentage: Decimal
    let fixedFee: Decimal
    let rushMultiplier: Decimal
    let minimumCharge: Decimal?
    
    init(
        metalMarkupPercentage: Decimal = 2.0,
        laborMarkupPercentage: Decimal = 1.5,
        fixedFee: Decimal = 0,
        rushMultiplier: Decimal = 1.5,
        minimumCharge: Decimal? = nil
    ) {
        self.metalMarkupPercentage = metalMarkupPercentage
        self.laborMarkupPercentage = laborMarkupPercentage
        self.fixedFee = fixedFee
        self.rushMultiplier = rushMultiplier
        self.minimumCharge = minimumCharge
    }
}

/// Represents a pricing rule that defines how to calculate service prices
struct PricingRule: Identifiable, Codable, Sendable {
    let id: String
    let companyId: String
    let name: String
    let description: String
    let formulaDefinition: PricingFormula
    let allowManualOverride: Bool
    let requireManagerApprovalIfOverrideExceedsPercent: Decimal?
    let isActive: Bool
    
    init(
        id: String = UUID().uuidString,
        companyId: String,
        name: String,
        description: String,
        formulaDefinition: PricingFormula = PricingFormula(),
        allowManualOverride: Bool = true,
        requireManagerApprovalIfOverrideExceedsPercent: Decimal? = 10.0,
        isActive: Bool = true
    ) {
        self.id = id
        self.companyId = companyId
        self.name = name
        self.description = description
        self.formulaDefinition = formulaDefinition
        self.allowManualOverride = allowManualOverride
        self.requireManagerApprovalIfOverrideExceedsPercent = requireManagerApprovalIfOverrideExceedsPercent
        self.isActive = isActive
    }
    
    /// Whether an override amount requires manager approval
    func requiresManagerApproval(originalPrice: Decimal, overridePrice: Decimal) -> Bool {
        guard let threshold = requireManagerApprovalIfOverrideExceedsPercent else { return false }
        
        let discountPercentage = ((originalPrice - overridePrice) / originalPrice) * 100
        return discountPercentage > threshold
    }
}

// MARK: - CloudKit Record Type
extension PricingRule {
    static let recordType = "PricingRule"
}
