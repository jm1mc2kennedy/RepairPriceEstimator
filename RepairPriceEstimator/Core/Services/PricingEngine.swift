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
    nonisolated(unsafe) private let repository: DataRepository
    
    init(repository: DataRepository = CloudKitService.shared) {
        self.repository = repository
    }
    
    /// Calculate pricing for a repair service with Springer's business rules
    func calculatePrice(
        serviceType: ServiceType,
        metalType: MetalType?,
        metalWeightGrams: Decimal?,
        laborMinutes: Int,
        isRush: Bool,
        companyId: String,
        springersItem: Bool = false,
        rushType: RushType = .standard,
        requestedDueDate: Date? = nil,
        sizingCategory: SizingCategory? = nil
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
        
        // Apply service-specific pricing if applicable
        let (serviceBaseRetail, serviceBaseCost) = calculateServiceSpecificPricing(
            serviceType: serviceType,
            sizingCategory: sizingCategory,
            metalType: metalType,
            notes: &notes
        )
        
        // Use service-specific pricing if available, otherwise calculate from formula
        let formula = pricingRule.formulaDefinition
        let baseCost: Decimal
        let baseRetail: Decimal
        let materialMarkup: Decimal
        let laborMarkup: Decimal
        
        if serviceBaseRetail > 0 || serviceBaseCost > 0 {
            // Use specific pricing from service catalog
            baseCost = serviceBaseCost
            baseRetail = serviceBaseRetail
            materialMarkup = 0 // Already included in specific pricing
            laborMarkup = 0    // Already included in specific pricing
        } else {
            // Calculate using formula
            baseCost = metalCost + laborCost + formula.fixedFee
            materialMarkup = metalCost * formula.metalMarkupPercentage
            laborMarkup = laborCost * formula.laborMarkupPercentage
            baseRetail = baseCost + materialMarkup + laborMarkup
        }
        
        // Apply Springer's rush policy
        let (rushMultiplier, rushFee, shouldApplyRush) = try await calculateSpringersRushPricing(
            baseRetail: baseRetail,
            rushType: rushType,
            springersItem: springersItem,
            serviceType: serviceType,
            requestedDueDate: requestedDueDate,
            formula: formula,
            notes: &notes,
            warnings: &warnings
        )
        
        // Calculate final retail price
        var finalRetail = baseRetail
        if shouldApplyRush {
            finalRetail = baseRetail * rushMultiplier
        }
        
        // Apply minimum charge if specified
        if let minimumCharge = formula.minimumCharge, finalRetail < minimumCharge {
            finalRetail = minimumCharge
            warnings.append("Applied minimum charge of \(formatCurrency(minimumCharge))")
        }
        
        // Add notes about the calculation
        if shouldApplyRush && rushMultiplier > 1.0 {
            notes.append("Rush multiplier applied: \(rushMultiplier)× (Springer's policy)")
        } else if rushType != .standard && springersItem {
            notes.append("Rush requested but no fee applied (Springer's purchase)")
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
        let predicate = NSPredicate(format: "companyId == %@ AND isActive == 1", companyId)
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
        let predicate = NSPredicate(format: "companyId == %@ AND metalType == %@ AND isActive == 1", companyId, metalType.rawValue)
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
        let predicate = NSPredicate(format: "companyId == %@ AND role == %@ AND isActive == 1", companyId, UserRole.benchJeweler.rawValue)
        let sortDescriptors = [NSSortDescriptor(key: "effectiveDate", ascending: false)]
        let rates = try await repository.query(LaborRate.self, predicate: predicate, sortDescriptors: sortDescriptors)
        
        guard let laborRate = rates.first else {
            warnings.append("No labor rate found for bench jeweler")
            // Use fallback rate
            let fallbackRate = Decimal(75) // $75/hour fallback
            let cost = Decimal(minutes) / 60 * fallbackRate
            warnings.append("Using fallback rate of \(formatCurrency(fallbackRate))/hour")
            return cost
        }
        
        let cost = laborRate.calculateCost(minutes: minutes)
        let hours = Decimal(minutes) / 60
        notes.append("\(hours)h labor at \(formatCurrency(laborRate.ratePerHour))/h = \(formatCurrency(cost))")
        
        return cost
    }
    
    private func calculateSpringersRushPricing(
        baseRetail: Decimal,
        rushType: RushType,
        springersItem: Bool,
        serviceType: ServiceType,
        requestedDueDate: Date?,
        formula: PricingFormula,
        notes: inout [String],
        warnings: inout [String]
    ) async throws -> (multiplier: Decimal, fee: Decimal, shouldApply: Bool) {
        
        guard rushType != .standard else {
            return (1.0, 0.0, false)
        }
        
        // Check if service supports rush
        guard serviceType.supportsRush else {
            warnings.append("Service type \(serviceType.name) cannot be rushed")
            return (1.0, 0.0, false)
        }
        
        // Springer's items get free rush service
        if springersItem {
            notes.append("Springer's purchase - no rush fee applied")
            return (1.0, 0.0, false)
        }
        
        // Check timing constraints for same-day
        if rushType == .sameDay {
            let now = Date()
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: now)
            
            if hour >= RushType.sameDayCutoff {
                warnings.append("Same-day request after 2PM cutoff - requires coordinator approval")
            }
            
            notes.append("Same-day rush service requested")
        }
        
        // Calculate rush timing
        if let dueDate = requestedDueDate {
            let hoursUntilDue = dueDate.timeIntervalSinceNow / 3600
            
            if hoursUntilDue <= 24 {
                notes.append("Same-day completion requested (\(Int(hoursUntilDue)) hours)")
            } else if hoursUntilDue <= 48 {
                notes.append("48-hour rush requested (\(Int(hoursUntilDue)) hours)")
            }
        }
        
        // Apply 1.5× multiplier for non-Springer's items
        let rushMultiplier = formula.rushMultiplier
        let rushFee = baseRetail * (rushMultiplier - 1)
        
        notes.append("Non-Springer's item - rush multiplier: \(rushMultiplier)×")
        
        return (rushMultiplier, rushFee, true)
    }
    
    /// Calculate service-specific pricing (e.g., ring sizing variations)
    private func calculateServiceSpecificPricing(
        serviceType: ServiceType,
        sizingCategory: SizingCategory?,
        metalType: MetalType?,
        notes: inout [String]
    ) -> (baseRetail: Decimal, baseCost: Decimal) {
        
        // For ring sizing, pricing varies by metal type and size category
        if serviceType.category == .jewelryRepair && 
           serviceType.name.contains("Sizing") &&
           !serviceType.isGenericSku {
            
            notes.append("Using specific pricing for \(serviceType.name)")
            return (serviceType.baseRetail, serviceType.baseCost)
        }
        
        // For generic SKUs, use base pricing that can be overridden
        if serviceType.isGenericSku {
            notes.append("Generic SKU - pricing will be entered manually")
            return (0, 0) // To be filled in manually by staff
        }
        
        // Standard service pricing
        return (serviceType.baseRetail, serviceType.baseCost)
    }
    
    /// Check if item was purchased at Springer's based on sales SKU
    func verifySpringersItem(salesSku: String?, companyId: String) async throws -> Bool {
        // This would integrate with sales system in production
        // For now, simple validation based on SKU pattern
        guard let sku = salesSku else { return false }
        
        // Springer's SKUs typically follow certain patterns
        let springersPatterns = ["PUR", "PRST", "SPR", "14K", "18K", "PLAT"]
        
        return springersPatterns.contains { pattern in
            sku.hasPrefix(pattern)
        }
    }
    
    /// Calculate watch bracelet sizing based on Springer's policy
    func calculateWatchBraceletSizing(
        springersItem: Bool,
        serviceDescription: String,
        companyId: String
    ) async throws -> PricingResult {
        
        let notes: [String] = springersItem 
            ? ["Watch bracelet sizing - no charge (Springer's purchase)"]
            : ["Watch bracelet sizing - $20 for non-Springer's items"]
        
        let retail: Decimal = springersItem ? 0 : 20
        let cost: Decimal = springersItem ? 0 : 5
        
        let breakdown = PricingBreakdown(
            metalCost: 0,
            laborCost: cost,
            fixedFees: 0,
            materialMarkup: 0,
            laborMarkup: retail - cost,
            rushFee: 0
        )
        
        return PricingResult(
            baseCost: cost,
            baseRetail: retail,
            rushMultiplier: 1.0,
            finalRetail: retail,
            breakdown: breakdown,
            notes: notes,
            warnings: []
        )
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
