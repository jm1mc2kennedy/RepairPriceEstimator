import Foundation
import CloudKit

/// Types of rush service based on Springer's policy
enum RushType: String, CaseIterable, Codable, Sendable {
    case sameDay = "SAME_DAY"           // Same-day completion (2PM cutoff)
    case within48Hours = "WITHIN_48H"   // Within 48 hours (1.5× multiplier for non-Springer's)
    case standard = "STANDARD"          // Standard turnaround
    
    var displayName: String {
        switch self {
        case .sameDay: return "Same Day"
        case .within48Hours: return "Within 48 Hours"
        case .standard: return "Standard"
        }
    }
    
    /// Whether this rush type applies the 1.5× multiplier
    func appliesRushMultiplier(for springersItem: Bool) -> Bool {
        switch self {
        case .sameDay, .within48Hours:
            return !springersItem // No rush fee for Springer's items
        case .standard:
            return false
        }
    }
    
    /// Cutoff time for same-day service
    static let sameDayCutoff = 14 // 2 PM in 24-hour format
}

/// Quote priority for queue management
enum QuotePriority: String, CaseIterable, Codable, Sendable {
    case urgent = "URGENT"              // Same-day or critical issues
    case high = "HIGH"                  // Client repairs, watch services
    case medium = "MEDIUM"              // Care plans, appraisals
    case low = "LOW"                    // Estate work, non-urgent items
    
    var displayName: String {
        switch self {
        case .urgent: return "Urgent"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .urgent: return 1
        case .high: return 2
        case .medium: return 3
        case .low: return 4
        }
    }
}

/// Quote status enumeration with comprehensive Springer's workflow
enum QuoteStatus: String, CaseIterable, Codable, Sendable {
    // Initial stages
    case draft = "DRAFT"
    case presented = "PRESENTED"
    case awaitingApproval = "AWAITING_APPROVAL"
    case approved = "APPROVED"
    case declined = "DECLINED"
    
    // Work stages
    case inShop = "IN_SHOP"
    case atVendor = "AT_VENDOR"
    case qualityReview = "QUALITY_REVIEW"
    case qualityFailed = "QUALITY_FAILED"
    case rework = "REWORK"
    
    // Completion stages
    case readyForPickup = "READY_FOR_PICKUP"
    case completed = "COMPLETED"
    case closed = "CLOSED"
    case cancelled = "CANCELLED"
    
    /// User-friendly display name for the status
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .presented: return "Presented"
        case .awaitingApproval: return "Awaiting Approval"
        case .approved: return "Approved"
        case .declined: return "Declined"
        case .inShop: return "In Shop"
        case .atVendor: return "At Vendor"
        case .qualityReview: return "Quality Review"
        case .qualityFailed: return "Quality Failed"
        case .rework: return "Rework Required"
        case .readyForPickup: return "Ready for Pickup"
        case .completed: return "Completed"
        case .closed: return "Closed"
        case .cancelled: return "Cancelled"
        }
    }
    
    /// Whether the quote can still be edited
    var canEdit: Bool {
        switch self {
        case .draft, .presented, .awaitingApproval:
            return true
        case .approved, .declined, .inShop, .atVendor, .qualityReview, .qualityFailed, .rework, .readyForPickup, .completed, .closed, .cancelled:
            return false
        }
    }
    
    /// Whether work can be started
    var canStartWork: Bool {
        switch self {
        case .approved:
            return true
        case .draft, .presented, .awaitingApproval, .declined, .inShop, .atVendor, .qualityReview, .qualityFailed, .rework, .readyForPickup, .completed, .closed, .cancelled:
            return false
        }
    }
    
    /// Whether the item is currently being worked on
    var isActiveWork: Bool {
        switch self {
        case .inShop, .atVendor, .rework:
            return true
        case .draft, .presented, .awaitingApproval, .approved, .declined, .qualityReview, .qualityFailed, .readyForPickup, .completed, .closed, .cancelled:
            return false
        }
    }
    
    /// Whether quality control is required for this status
    var requiresQualityControl: Bool {
        switch self {
        case .inShop, .atVendor, .rework:
            return true
        case .draft, .presented, .awaitingApproval, .approved, .declined, .qualityReview, .qualityFailed, .readyForPickup, .completed, .closed, .cancelled:
            return false
        }
    }
    
    /// Next possible statuses based on business rules
    var possibleNextStatuses: [QuoteStatus] {
        switch self {
        case .draft:
            return [.presented, .cancelled]
        case .presented:
            return [.awaitingApproval, .approved, .declined, .draft]
        case .awaitingApproval:
            return [.approved, .declined, .presented]
        case .approved:
            return [.inShop, .atVendor, .cancelled]
        case .declined:
            return [.presented, .closed]
        case .inShop:
            return [.qualityReview, .atVendor, .cancelled]
        case .atVendor:
            return [.inShop, .qualityReview, .cancelled]
        case .qualityReview:
            return [.readyForPickup, .qualityFailed]
        case .qualityFailed:
            return [.rework, .qualityReview, .cancelled]
        case .rework:
            return [.qualityReview, .cancelled]
        case .readyForPickup:
            return [.completed, .inShop] // Can go back for additional work
        case .completed:
            return [.closed]
        case .closed, .cancelled:
            return [] // Terminal states
        }
    }
    
    /// Priority for queue sorting
    var queuePriority: Int {
        switch self {
        case .qualityFailed, .rework: return 1 // Highest priority - fix issues
        case .readyForPickup: return 2 // Customer waiting
        case .inShop, .qualityReview: return 3 // Active work
        case .approved: return 4 // Ready to start
        case .atVendor: return 5 // Waiting on vendor
        case .awaitingApproval, .presented: return 6 // Waiting on customer
        case .draft: return 7 // Incomplete
        case .declined, .completed, .closed, .cancelled: return 8 // Inactive
        }
    }
}

/// Represents a repair quote in the system
struct Quote: Identifiable, Codable, Sendable {
    let id: String // Human-readable ID like "Q-2025-000123"
    let companyId: String
    let storeId: String
    let guestId: String
    var status: QuoteStatus
    let createdAt: Date
    var updatedAt: Date
    let validUntil: Date
    let currencyCode: String
    var subtotal: Decimal
    var tax: Decimal
    var total: Decimal
    var rushMultiplierApplied: Decimal
    let pricingVersion: String
    var internalNotes: String?
    var customerFacingNotes: String?
    
    // Springer's specific enhancements
    var springersItem: Bool              // Whether purchased at Springer's (affects rush pricing)
    var salesSku: String?               // Original sales SKU if Springer's item
    var rushType: RushType?             // Type of rush service
    var requestedDueDate: Date?         // When customer requested completion
    var promisedDueDate: Date?          // When we promised completion
    var coordinatorApprovalRequired: Bool // For same-day rush beyond normal slots
    var coordinatorApprovalGranted: Bool
    var intakeChecklistId: String?      // Link to intake checklist
    var primaryServiceCategory: ServiceCategory // JR, WS, BC, LIQ classification
    var priority: QuotePriority         // Based on category and other factors
    var estimateApproved: Bool          // Whether customer approved estimate
    var preApprovedLimit: Decimal?      // Pre-approved spending limit
    
    init(
        id: String,
        companyId: String,
        storeId: String,
        guestId: String,
        status: QuoteStatus = .draft,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        validUntil: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
        currencyCode: String = "USD",
        subtotal: Decimal = 0,
        tax: Decimal = 0,
        total: Decimal = 0,
        rushMultiplierApplied: Decimal = 1.0,
        pricingVersion: String = "1.0",
        internalNotes: String? = nil,
        customerFacingNotes: String? = nil,
        springersItem: Bool = false,
        salesSku: String? = nil,
        rushType: RushType? = nil,
        requestedDueDate: Date? = nil,
        promisedDueDate: Date? = nil,
        coordinatorApprovalRequired: Bool = false,
        coordinatorApprovalGranted: Bool = false,
        intakeChecklistId: String? = nil,
        primaryServiceCategory: ServiceCategory = .jewelryRepair,
        priority: QuotePriority = .medium,
        estimateApproved: Bool = false,
        preApprovedLimit: Decimal? = nil
    ) {
        self.id = id
        self.companyId = companyId
        self.storeId = storeId
        self.guestId = guestId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.validUntil = validUntil
        self.currencyCode = currencyCode
        self.subtotal = subtotal
        self.tax = tax
        self.total = total
        self.rushMultiplierApplied = rushMultiplierApplied
        self.pricingVersion = pricingVersion
        self.internalNotes = internalNotes
        self.customerFacingNotes = customerFacingNotes
        self.springersItem = springersItem
        self.salesSku = salesSku
        self.rushType = rushType
        self.requestedDueDate = requestedDueDate
        self.promisedDueDate = promisedDueDate
        self.coordinatorApprovalRequired = coordinatorApprovalRequired
        self.coordinatorApprovalGranted = coordinatorApprovalGranted
        self.intakeChecklistId = intakeChecklistId
        self.primaryServiceCategory = primaryServiceCategory
        self.priority = priority
        self.estimateApproved = estimateApproved
        self.preApprovedLimit = preApprovedLimit
    }
    
    /// Updates the total based on subtotal and tax
    mutating func updateTotal() {
        self.total = self.subtotal + self.tax
        self.updatedAt = Date()
    }
    
    /// Whether rush fees should be applied based on Springer's policy
    var shouldApplyRushFees: Bool {
        guard let rushType = rushType else { return false }
        return rushType.appliesRushMultiplier(for: springersItem)
    }
    
    /// Whether this quote requires coordinator approval for rush timing
    var requiresCoordinatorApproval: Bool {
        guard let rushType = rushType else { return false }
        
        // Same-day after 2PM requires approval
        if rushType == .sameDay {
            let now = Date()
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: now)
            
            if hour >= RushType.sameDayCutoff {
                return true
            }
        }
        
        return coordinatorApprovalRequired
    }
    
    /// Time until promised due date (nil if no due date set)
    var timeUntilDue: TimeInterval? {
        guard let dueDate = promisedDueDate else { return nil }
        return dueDate.timeIntervalSinceNow
    }
    
    /// Whether the quote is overdue
    var isOverdue: Bool {
        guard let dueDate = promisedDueDate else { return false }
        return dueDate < Date() && status != .completed && status != .closed
    }
    
    /// Auto-calculate priority based on category and rush status
    mutating func updatePriority() {
        if rushType == .sameDay {
            priority = .urgent
        } else if rushType == .within48Hours || primaryServiceCategory == .jewelryRepair {
            priority = .high
        } else if primaryServiceCategory == .watchService || primaryServiceCategory == .carePlan {
            priority = .medium
        } else {
            priority = .low
        }
        updatedAt = Date()
    }
    
    /// Whether estimate needs customer approval
    var needsEstimateApproval: Bool {
        guard !estimateApproved else { return false }
        
        // Check if total exceeds pre-approved limit
        if let limit = preApprovedLimit {
            return total > limit
        }
        
        // Default: all estimates need approval unless pre-approved
        return true
    }
}

// MARK: - CloudKit Record Type
extension Quote {
    static let recordType = "Quote"
}
