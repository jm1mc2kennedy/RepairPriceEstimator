import Foundation
import CloudKit

/// Types of appraisal services
enum AppraisalType: String, CaseIterable, Codable, Sendable {
    case insurance = "INSURANCE"
    case estate = "ESTATE"
    case donation = "DONATION"
    case damage = "DAMAGE"
    case divorce = "DIVORCE"
    case probate = "PROBATE"
    case gemId = "GEM_ID"
    case hypothetical = "HYPOTHETICAL"
    case virtual = "VIRTUAL"
    case update = "UPDATE"
    
    var displayName: String {
        switch self {
        case .insurance: return "Insurance"
        case .estate: return "Estate"
        case .donation: return "Donation"
        case .damage: return "Damage/Loss"
        case .divorce: return "Divorce"
        case .probate: return "Probate"
        case .gemId: return "Gem Identification"
        case .hypothetical: return "Hypothetical"
        case .virtual: return "Virtual Appraisal"
        case .update: return "Update/Review"
        }
    }
    
    /// Base pricing tier for this appraisal type
    var basePricingTier: AppraisalPricingTier {
        switch self {
        case .insurance, .estate, .divorce, .probate: return .standard
        case .donation, .damage: return .standard
        case .gemId: return .gemIdentification
        case .hypothetical, .virtual: return .specialized
        case .update: return .update
        }
    }
}

/// Appraisal pricing tiers based on complexity and carat weight
enum AppraisalPricingTier: String, CaseIterable, Codable, Sendable {
    case standard = "STANDARD"
    case gemIdentification = "GEM_ID"
    case specialized = "SPECIALIZED"
    case update = "UPDATE"
    case sarinReport = "SARIN_REPORT"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard Appraisal"
        case .gemIdentification: return "Gem Identification"
        case .specialized: return "Specialized Service"
        case .update: return "Update/Review"
        case .sarinReport: return "Sarin Report"
        }
    }
    
    /// Base fee structure for this tier
    var baseFeeStructure: AppraisalFeeStructure {
        switch self {
        case .standard:
            return AppraisalFeeStructure(
                firstItemBase: 150,
                additionalItemFee: 75,
                caratTiers: [
                    AppraisalCaratTier(maxCarats: 1.0, multiplier: 1.0),
                    AppraisalCaratTier(maxCarats: 2.0, multiplier: 1.3),
                    AppraisalCaratTier(maxCarats: 3.0, multiplier: 1.6),
                    AppraisalCaratTier(maxCarats: 5.0, multiplier: 2.0),
                    AppraisalCaratTier(maxCarats: 99.0, multiplier: 2.5)
                ]
            )
        case .gemIdentification:
            return AppraisalFeeStructure(
                firstItemBase: 75,
                additionalItemFee: 50,
                caratTiers: [
                    AppraisalCaratTier(maxCarats: 99.0, multiplier: 1.0)
                ]
            )
        case .specialized:
            return AppraisalFeeStructure(
                firstItemBase: 250,
                additionalItemFee: 125,
                caratTiers: [
                    AppraisalCaratTier(maxCarats: 1.0, multiplier: 1.0),
                    AppraisalCaratTier(maxCarats: 99.0, multiplier: 1.5)
                ]
            )
        case .update:
            return AppraisalFeeStructure(
                firstItemBase: 75,  // Half price for updates
                additionalItemFee: 38,
                caratTiers: [
                    AppraisalCaratTier(maxCarats: 99.0, multiplier: 1.0)
                ]
            )
        case .sarinReport:
            return AppraisalFeeStructure(
                firstItemBase: 200,
                additionalItemFee: 100,
                caratTiers: [
                    AppraisalCaratTier(maxCarats: 99.0, multiplier: 1.0)
                ]
            )
        }
    }
}

/// Fee structure for appraisal services
struct AppraisalFeeStructure: Codable, Sendable {
    let firstItemBase: Decimal
    let additionalItemFee: Decimal
    let caratTiers: [AppraisalCaratTier]
    
    /// Calculate fee for given number of items and largest carat weight
    func calculateFee(itemCount: Int, largestCaratWeight: Decimal) -> Decimal {
        guard itemCount > 0 else { return 0 }
        
        // Find appropriate carat tier
        let tier = caratTiers.first { largestCaratWeight <= $0.maxCarats } ?? caratTiers.last!
        
        // Calculate base fee for first item
        let firstItemFee = firstItemBase * tier.multiplier
        
        // Calculate additional items fee
        let additionalFee = additionalItemFee * tier.multiplier * Decimal(max(0, itemCount - 1))
        
        return firstItemFee + additionalFee
    }
}

/// Carat weight tiers for pricing
struct AppraisalCaratTier: Codable, Sendable {
    let maxCarats: Decimal
    let multiplier: Decimal
}

/// Appraisal service record
struct AppraisalService: Identifiable, Codable, Sendable {
    let id: String
    let quoteId: String
    let guestId: String
    let appraiserId: String
    
    // Service details
    let appraisalType: AppraisalType
    let pricingTier: AppraisalPricingTier
    let itemCount: Int
    let largestCaratWeight: Decimal
    
    // Pricing
    let calculatedFee: Decimal
    let finalFee: Decimal
    let feeOverrideReason: String?
    
    // Timing
    let createdAt: Date
    let scheduledDate: Date?
    let completedDate: Date?
    let expedited: Bool
    let expediteMultiplier: Decimal // 1.5× for some expedited appraisals
    
    // Special services
    let sarinReportRequested: Bool
    let gemIdRequested: Bool
    let photoDocumentation: Bool
    let certificationVerification: Bool
    
    // Update/review information
    let isUpdate: Bool
    let originalAppraisalDate: Date?
    let updateDiscount: Decimal? // Half price within timeframe
    
    // Status
    let status: AppraisalStatus
    let deliveryMethod: AppraisalDeliveryMethod
    let notes: String?
    
    init(
        id: String = UUID().uuidString,
        quoteId: String,
        guestId: String,
        appraiserId: String,
        appraisalType: AppraisalType,
        pricingTier: AppraisalPricingTier? = nil,
        itemCount: Int,
        largestCaratWeight: Decimal,
        calculatedFee: Decimal,
        finalFee: Decimal? = nil,
        feeOverrideReason: String? = nil,
        createdAt: Date = Date(),
        scheduledDate: Date? = nil,
        completedDate: Date? = nil,
        expedited: Bool = false,
        expediteMultiplier: Decimal = 1.5,
        sarinReportRequested: Bool = false,
        gemIdRequested: Bool = false,
        photoDocumentation: Bool = true,
        certificationVerification: Bool = false,
        isUpdate: Bool = false,
        originalAppraisalDate: Date? = nil,
        updateDiscount: Decimal? = nil,
        status: AppraisalStatus = .scheduled,
        deliveryMethod: AppraisalDeliveryMethod = .email,
        notes: String? = nil
    ) {
        self.id = id
        self.quoteId = quoteId
        self.guestId = guestId
        self.appraiserId = appraiserId
        self.appraisalType = appraisalType
        self.pricingTier = pricingTier ?? appraisalType.basePricingTier
        self.itemCount = itemCount
        self.largestCaratWeight = largestCaratWeight
        self.calculatedFee = calculatedFee
        self.finalFee = finalFee ?? calculatedFee
        self.feeOverrideReason = feeOverrideReason
        self.createdAt = createdAt
        self.scheduledDate = scheduledDate
        self.completedDate = completedDate
        self.expedited = expedited
        self.expediteMultiplier = expediteMultiplier
        self.sarinReportRequested = sarinReportRequested
        self.gemIdRequested = gemIdRequested
        self.photoDocumentation = photoDocumentation
        self.certificationVerification = certificationVerification
        self.isUpdate = isUpdate
        self.originalAppraisalDate = originalAppraisalDate
        self.updateDiscount = updateDiscount
        self.status = status
        self.deliveryMethod = deliveryMethod
        self.notes = notes
    }
    
    /// Whether update discount applies (half price within 10 years)
    var qualifiesForUpdateDiscount: Bool {
        guard isUpdate,
              let originalDate = originalAppraisalDate else { return false }
        
        let yearsSinceOriginal = Calendar.current.dateComponents([.year], from: originalDate, to: Date()).year ?? 0
        return yearsSinceOriginal <= 10
    }
    
    /// Total cost including all additional services
    var totalCost: Decimal {
        var total = finalFee
        
        if sarinReportRequested {
            total += AppraisalPricingTier.sarinReport.baseFeeStructure.firstItemBase
        }
        
        if expedited {
            total *= expediteMultiplier
        }
        
        return total
    }
}

/// Appraisal status tracking
enum AppraisalStatus: String, CaseIterable, Codable, Sendable {
    case scheduled = "SCHEDULED"
    case inProgress = "IN_PROGRESS"
    case review = "REVIEW"
    case completed = "COMPLETED"
    case delivered = "DELIVERED"
    case cancelled = "CANCELLED"
    case onHold = "ON_HOLD"
    
    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .review: return "Under Review"
        case .completed: return "Completed"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        case .onHold: return "On Hold"
        }
    }
}

/// Appraisal delivery methods
enum AppraisalDeliveryMethod: String, CaseIterable, Codable, Sendable {
    case email = "EMAIL"
    case pickup = "PICKUP"
    case mail = "MAIL"
    case courier = "COURIER"
    
    var displayName: String {
        switch self {
        case .email: return "Email"
        case .pickup: return "In-Store Pickup"
        case .mail: return "US Mail"
        case .courier: return "Courier"
        }
    }
}

// MARK: - CloudKit Record Type
extension AppraisalService {
    static let recordType = "AppraisalService"
}

// MARK: - Appraisal Calculator

struct AppraisalCalculator {
    /// Calculate appraisal pricing based on Springer's policy
    static func calculateAppraisalFee(
        type: AppraisalType,
        itemCount: Int,
        largestCaratWeight: Decimal,
        isUpdate: Bool = false,
        originalAppraisalDate: Date? = nil,
        expedited: Bool = false,
        sarinReport: Bool = false
    ) -> AppraisalPricingResult {
        
        let tier = type.basePricingTier
        let feeStructure = tier.baseFeeStructure
        
        // Calculate base fee
        var baseFee = feeStructure.calculateFee(itemCount: itemCount, largestCaratWeight: largestCaratWeight)
        
        // Apply update discount if applicable
        if isUpdate, let originalDate = originalAppraisalDate {
            let yearsSince = Calendar.current.dateComponents([.year], from: originalDate, to: Date()).year ?? 0
            if yearsSince <= 10 {
                baseFee = baseFee / 2 // Half price for updates within 10 years
            }
        }
        
        // Add specialty services
        var totalFee = baseFee
        var additionalServices: [String] = []
        
        if sarinReport {
            let sarinFee = AppraisalPricingTier.sarinReport.baseFeeStructure.firstItemBase
            totalFee += sarinFee
            additionalServices.append("Sarin Report (+$\(sarinFee))")
        }
        
        // Apply expedite multiplier
        if expedited {
            totalFee *= 1.5
            additionalServices.append("Expedited Service (1.5×)")
        }
        
        return AppraisalPricingResult(
            baseFee: baseFee,
            totalFee: totalFee,
            tier: tier,
            itemCount: itemCount,
            largestCaratWeight: largestCaratWeight,
            updateDiscountApplied: isUpdate && baseFee < feeStructure.calculateFee(itemCount: itemCount, largestCaratWeight: largestCaratWeight),
            additionalServices: additionalServices
        )
    }
}

/// Result of appraisal pricing calculation
struct AppraisalPricingResult: Sendable {
    let baseFee: Decimal
    let totalFee: Decimal
    let tier: AppraisalPricingTier
    let itemCount: Int
    let largestCaratWeight: Decimal
    let updateDiscountApplied: Bool
    let additionalServices: [String]
    
    /// Formatted breakdown of pricing
    var pricingBreakdown: String {
        var breakdown = "Appraisal Fee Breakdown:\n"
        breakdown += "• Base fee (\(tier.displayName)): $\(baseFee)\n"
        
        if updateDiscountApplied {
            breakdown += "• Update discount applied (50% off)\n"
        }
        
        for service in additionalServices {
            breakdown += "• \(service)\n"
        }
        
        breakdown += "Total: $\(totalFee)"
        return breakdown
    }
}
