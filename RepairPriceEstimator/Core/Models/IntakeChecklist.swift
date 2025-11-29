import Foundation
import CloudKit

/// Condition assessment findings during intake inspection
struct ConditionFinding: Codable, Sendable {
    let category: ConditionCategory
    let severity: ConditionSeverity
    let description: String
    let recommendedServices: [String] // Service type IDs
    let location: String? // Where on the piece (e.g., "prong #3", "shank", "clasp")
    
    init(
        category: ConditionCategory,
        severity: ConditionSeverity,
        description: String,
        recommendedServices: [String] = [],
        location: String? = nil
    ) {
        self.category = category
        self.severity = severity
        self.description = description
        self.recommendedServices = recommendedServices
        self.location = location
    }
}

/// Categories of conditions that can be found during inspection
enum ConditionCategory: String, CaseIterable, Codable, Sendable {
    // Stone conditions
    case stoneChip = "STONE_CHIP"
    case stoneCrack = "STONE_CRACK"
    case stoneAbrasion = "STONE_ABRASION"
    case stoneFractureFilling = "STONE_FRACTURE_FILLING"
    case stoneMissing = "STONE_MISSING"
    case stoneLoose = "STONE_LOOSE"
    
    // Metal conditions
    case metalCrack = "METAL_CRACK"
    case metalBreak = "METAL_BREAK"
    case metalPorosity = "METAL_POROSITY"
    case metalMarks = "METAL_MARKS"
    case metalThinning = "METAL_THINNING"
    
    // Setting conditions
    case prongBent = "PRONG_BENT"
    case prongBroken = "PRONG_BROKEN"
    case prongWorn = "PRONG_WORN"
    case channelWorn = "CHANNEL_WORN"
    case shankThin = "SHANK_THIN"
    
    // Chain/bracelet conditions
    case linkWorn = "LINK_WORN"
    case linkStretched = "LINK_STRETCHED"
    case bailWorn = "BAIL_WORN"
    case hingeWorn = "HINGE_WORN"
    case claspWorn = "CLASP_WORN"
    
    // General conditions
    case finish = "FINISH"
    case sizing = "SIZING"
    case general = "GENERAL"
    
    var displayName: String {
        switch self {
        case .stoneChip: return "Stone Chip"
        case .stoneCrack: return "Stone Crack"
        case .stoneAbrasion: return "Stone Abrasion"
        case .stoneFractureFilling: return "Stone Fracture Filling"
        case .stoneMissing: return "Missing Stone"
        case .stoneLoose: return "Loose Stone"
        case .metalCrack: return "Metal Crack"
        case .metalBreak: return "Metal Break"
        case .metalPorosity: return "Metal Porosity"
        case .metalMarks: return "Metal Marks"
        case .metalThinning: return "Metal Thinning"
        case .prongBent: return "Bent Prong"
        case .prongBroken: return "Broken Prong"
        case .prongWorn: return "Worn Prong"
        case .channelWorn: return "Worn Channel"
        case .shankThin: return "Thin Shank"
        case .linkWorn: return "Worn Links"
        case .linkStretched: return "Stretched Links"
        case .bailWorn: return "Worn Bail"
        case .hingeWorn: return "Worn Hinge"
        case .claspWorn: return "Worn Clasp"
        case .finish: return "Finish Issue"
        case .sizing: return "Sizing Needed"
        case .general: return "General Issue"
        }
    }
}

/// Severity levels for condition findings
enum ConditionSeverity: String, CaseIterable, Codable, Sendable {
    case minor = "MINOR"           // Cosmetic, no immediate risk
    case moderate = "MODERATE"     // Should be addressed but not urgent
    case major = "MAJOR"           // Significant issue, affects durability
    case critical = "CRITICAL"     // Immediate risk of loss or damage
    case unsafeToClean = "UNSAFE_TO_CLEAN" // Cannot be cleaned safely
    
    var displayName: String {
        switch self {
        case .minor: return "Minor"
        case .moderate: return "Moderate"
        case .major: return "Major"
        case .critical: return "Critical"
        case .unsafeToClean: return "Unsafe to Clean"
        }
    }
    
    var color: String {
        switch self {
        case .minor: return "green"
        case .moderate: return "yellow"
        case .major: return "orange"
        case .critical: return "red"
        case .unsafeToClean: return "purple"
        }
    }
}

/// Comprehensive intake checklist for jewelry and watches
struct IntakeChecklist: Identifiable, Codable, Sendable {
    let id: String
    let quoteId: String
    let inspectorId: String
    let inspectionDate: Date
    
    // Condition findings
    let findings: [ConditionFinding]
    let overallCondition: ConditionSeverity
    let safeToClean: Bool
    
    // Mandatory intake fields
    let isRush: Bool
    let salespersonId: String?
    let repairType: ServiceCategory
    let photosRequired: Bool
    let photosCaptured: Int
    let shortDescription: String
    let extendedDescription: String
    let conditionNotes: String
    
    // Estimate and approval
    let estimateRequired: Bool
    let preApprovedLimit: Decimal?
    let requiresApproval: Bool
    
    // Shipping and handling
    let shippingDepositTaken: Bool
    let shippingDepositAmount: Decimal?
    let specialHandling: String?
    
    // Due date and timing
    let requestedDueDate: Date?
    let promisedDueDate: Date?
    let dueDateRealistic: Bool
    
    // Additional flags
    let springersItem: Bool           // Whether purchased at Springer's
    let highValue: Bool              // Requires special handling
    let insuranceRequired: Bool      // For high-value items
    let customerPresent: Bool        // Customer present during intake
    
    init(
        id: String = UUID().uuidString,
        quoteId: String,
        inspectorId: String,
        inspectionDate: Date = Date(),
        findings: [ConditionFinding] = [],
        overallCondition: ConditionSeverity = .minor,
        safeToClean: Bool = true,
        isRush: Bool = false,
        salespersonId: String? = nil,
        repairType: ServiceCategory,
        photosRequired: Bool = true,
        photosCaptured: Int = 0,
        shortDescription: String,
        extendedDescription: String,
        conditionNotes: String,
        estimateRequired: Bool = true,
        preApprovedLimit: Decimal? = nil,
        requiresApproval: Bool = true,
        shippingDepositTaken: Bool = false,
        shippingDepositAmount: Decimal? = nil,
        specialHandling: String? = nil,
        requestedDueDate: Date? = nil,
        promisedDueDate: Date? = nil,
        dueDateRealistic: Bool = true,
        springersItem: Bool = false,
        highValue: Bool = false,
        insuranceRequired: Bool = false,
        customerPresent: Bool = true
    ) {
        self.id = id
        self.quoteId = quoteId
        self.inspectorId = inspectorId
        self.inspectionDate = inspectionDate
        self.findings = findings
        self.overallCondition = overallCondition
        self.safeToClean = safeToClean
        self.isRush = isRush
        self.salespersonId = salespersonId
        self.repairType = repairType
        self.photosRequired = photosRequired
        self.photosCaptured = photosCaptured
        self.shortDescription = shortDescription
        self.extendedDescription = extendedDescription
        self.conditionNotes = conditionNotes
        self.estimateRequired = estimateRequired
        self.preApprovedLimit = preApprovedLimit
        self.requiresApproval = requiresApproval
        self.shippingDepositTaken = shippingDepositTaken
        self.shippingDepositAmount = shippingDepositAmount
        self.specialHandling = specialHandling
        self.requestedDueDate = requestedDueDate
        self.promisedDueDate = promisedDueDate
        self.dueDateRealistic = dueDateRealistic
        self.springersItem = springersItem
        self.highValue = highValue
        self.insuranceRequired = insuranceRequired
        self.customerPresent = customerPresent
    }
    
    /// Critical findings that require immediate attention
    var criticalFindings: [ConditionFinding] {
        findings.filter { $0.severity == .critical || $0.severity == .unsafeToClean }
    }
    
    /// Whether all mandatory fields are completed
    var isComplete: Bool {
        !shortDescription.isEmpty &&
        !extendedDescription.isEmpty &&
        !conditionNotes.isEmpty &&
        (!photosRequired || photosCaptured > 0) &&
        (!requiresApproval || preApprovedLimit != nil) &&
        promisedDueDate != nil
    }
    
    /// Auto-generated recommended services based on findings
    var recommendedServices: [String] {
        findings.flatMap { $0.recommendedServices }.uniqued()
    }
}

// MARK: - CloudKit Record Type
extension IntakeChecklist {
    static let recordType = "IntakeChecklist"
}

// MARK: - Array Extension for Unique Elements
extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
