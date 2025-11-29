import Foundation

/// Result of a pricing calculation
struct PricingResult: Sendable {
    let baseCost: Decimal
    let baseRetail: Decimal
    let rushMultiplier: Decimal
    let finalRetail: Decimal
    let breakdown: PricingBreakdown
    let notes: [String]
    let warnings: [String]
    
    /// Whether this pricing calculation has any warnings
    var hasWarnings: Bool {
        !warnings.isEmpty
    }
}

/// Detailed breakdown of pricing components
struct PricingBreakdown: Sendable {
    let metalCost: Decimal
    let laborCost: Decimal
    let fixedFees: Decimal
    let materialMarkup: Decimal
    let laborMarkup: Decimal
    let rushFee: Decimal
    
    /// Total cost before markup
    var totalCost: Decimal {
        metalCost + laborCost + fixedFees
    }
    
    /// Total markup applied
    var totalMarkup: Decimal {
        materialMarkup + laborMarkup
    }
}

/// Service for calculating repair pricing based on business rules
@MainActor
final class PricingEngine: ObservableObject {
    private let repository: DataRepository
    
    init(repository: DataRepository = CloudKitService.shared) {
        self.repository = repository
    }
    
    /// Calculate pricing for a repair service
    func calculatePrice(
        serviceType: ServiceType,
        metalType: MetalType?,
        metalWeightGrams: Decimal?,
        laborMinutes: Int,
        isRush: Bool,
        companyId: String
    ) async throws -> PricingResult {
        
        var notes: [String] = []
        var warnings: [String] = []
        
        // Get pricing rule for the service
        let pricingRule = try await getPricingRule(for: serviceType, companyId: companyId)
        
        // Calculate metal cost
        let metalCost = try await calculateMetalCost(
            metalType: metalType,
            weightGrams: metalWeightGrams,
            companyId: companyId,
            notes: &notes,
            warnings: &warnings
        )
        
        // Calculate labor cost
        let laborCost = try await calculateLaborCost(
            minutes: laborMinutes,
            companyId: companyId,
            notes: &notes,
            warnings: &warnings
        )
        
        // Apply formula
        let formula = pricingRule.formulaDefinition
        let baseCost = metalCost + laborCost + formula.fixedFee
        
        // Calculate markups
        let materialMarkup = metalCost * formula.metalMarkupPercentage
        let laborMarkup = laborCost * formula.laborMarkupPercentage
        let baseRetail = baseCost + materialMarkup + laborMarkup
        
        // Apply rush multiplier
        let rushMultiplier = isRush ? formula.rushMultiplier : 1.0
        let rushFee = isRush ? (baseRetail * (rushMultiplier - 1)) : 0
        
        // Calculate final retail price
        var finalRetail = baseRetail * rushMultiplier
        
        // Apply minimum charge if specified
        if let minimumCharge = formula.minimumCharge, finalRetail < minimumCharge {
            finalRetail = minimumCharge
            warnings.append("Applied minimum charge of \(formatCurrency(minimumCharge))")
        }
        
        // Add notes about the calculation
        if isRush {
            notes.append("Rush multiplier applied: \(rushMultiplier)×")
        }
        
        let breakdown = PricingBreakdown(
            metalCost: metalCost,
            laborCost: laborCost,
            fixedFees: formula.fixedFee,
            materialMarkup: materialMarkup,
            laborMarkup: laborMarkup,
            rushFee: rushFee
        )
        
        return PricingResult(
            baseCost: baseCost,
            baseRetail: baseRetail,
            rushMultiplier: rushMultiplier,
            finalRetail: finalRetail,
            breakdown: breakdown,
            notes: notes,
            warnings: warnings
        )
    }
    
    // MARK: - Private Methods
    
    private func getPricingRule(for serviceType: ServiceType, companyId: String) async throws -> PricingRule {
        // If service type has a specific pricing rule, use it
        if let pricingFormulaId = serviceType.pricingFormulaId {
            if let rule = try await repository.fetch(PricingRule.self, id: pricingFormulaId) {
                return rule
            }
        }
        
        // Otherwise, get the default pricing rule for the company
        let predicate = NSPredicate(format: "companyId == %@ AND isActive == YES", companyId)
        let rules = try await repository.query(PricingRule.self, predicate: predicate, sortDescriptors: nil)
        
        guard let defaultRule = rules.first else {
            throw PricingEngineError.noPricingRuleFound
        }
        
        return defaultRule
    }
    
    private func calculateMetalCost(
        metalType: MetalType?,
        weightGrams: Decimal?,
        companyId: String,
        notes: inout [String],
        warnings: inout [String]
    ) async throws -> Decimal {
        
        guard let metalType = metalType,
              let weightGrams = weightGrams,
              weightGrams > 0 else {
            // No metal work required
            notes.append("No metal work required")
            return 0
        }
        
        // Only calculate cost for precious metals
        guard metalType.requiresMarketRatePricing else {
            notes.append("Metal type \(metalType.displayName) uses fixed pricing")
            return 0
        }
        
        // Get current market rate
        let predicate = NSPredicate(format: "companyId == %@ AND metalType == %@ AND isActive == YES", companyId, metalType.rawValue)
        let sortDescriptors = [NSSortDescriptor(key: "effectiveDate", ascending: false)]
        let rates = try await repository.query(MetalMarketRate.self, predicate: predicate, sortDescriptors: sortDescriptors)
        
        guard let currentRate = rates.first else {
            warnings.append("No market rate found for \(metalType.displayName)")
            return 0
        }
        
        // Check if rate is recent (within 7 days)
        let daysSinceUpdate = Calendar.current.dateComponents([.day], from: currentRate.effectiveDate, to: Date()).day ?? 0
        if daysSinceUpdate > 7 {
            warnings.append("Market rate for \(metalType.displayName) is \(daysSinceUpdate) days old")
        }
        
        let cost = weightGrams * currentRate.rate
        notes.append("\(weightGrams)g \(metalType.displayName) at \(formatCurrency(currentRate.rate))/g = \(formatCurrency(cost))")
        
        return cost
    }
    
    private func calculateLaborCost(
        minutes: Int,
        companyId: String,
        notes: inout [String],
        warnings: inout [String]
    ) async throws -> Decimal {
        
        guard minutes > 0 else {
            notes.append("No labor time required")
            return 0
        }
        
        // Get bench jeweler labor rate
        let predicate = NSPredicate(format: "companyId == %@ AND role == %@ AND isActive == YES", companyId, UserRole.benchJeweler.rawValue)
        let sortDescriptors = [NSSortDescriptor(key: "effectiveDate", ascending: false)]
        let rates = try await repository.query(LaborRate.self, predicate: predicate, sortDescriptors: sortDescriptors)
        
        guard let laborRate = rates.first else {
            warnings.append("No labor rate found for bench jeweler")
            // Use fallback rate
            let fallbackRate = Decimal(75) // $75/hour fallback
            let cost = laborRate?.calculateCost(minutes: minutes) ?? (Decimal(minutes) / 60 * fallbackRate)
            warnings.append("Using fallback rate of \(formatCurrency(fallbackRate))/hour")
            return cost
        }
        
        let cost = laborRate.calculateCost(minutes: minutes)
        let hours = Decimal(minutes) / 60
        notes.append("\(hours)h labor at \(formatCurrency(laborRate.ratePerHour))/h = \(formatCurrency(cost))")
        
        return cost
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }
}

// MARK: - Errors

enum PricingEngineError: Error, LocalizedError {
    case noPricingRuleFound
    case invalidServiceType
    case missingMetalData
    case invalidLaborTime
    
    var errorDescription: String? {
        switch self {
        case .noPricingRuleFound:
            return "No pricing rule found for this service"
        case .invalidServiceType:
            return "Invalid or inactive service type"
        case .missingMetalData:
            return "Metal type and weight are required for metal work"
        case .invalidLaborTime:
            return "Labor time must be greater than zero"
        }
    }
}
