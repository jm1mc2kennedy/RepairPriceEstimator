import Foundation
import CloudKit

/// Quote status enumeration
enum QuoteStatus: String, CaseIterable, Codable, Sendable {
    case draft = "DRAFT"
    case presented = "PRESENTED"
    case approved = "APPROVED"
    case declined = "DECLINED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case closed = "CLOSED"
    
    /// User-friendly display name for the status
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .presented: return "Presented"
        case .approved: return "Approved"
        case .declined: return "Declined"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .closed: return "Closed"
        }
    }
    
    /// Whether the quote can still be edited
    var canEdit: Bool {
        switch self {
        case .draft, .presented:
            return true
        case .approved, .declined, .inProgress, .completed, .closed:
            return false
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
        customerFacingNotes: String? = nil
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
    }
    
    /// Updates the total based on subtotal and tax
    mutating func updateTotal() {
        self.total = self.subtotal + self.tax
        self.updatedAt = Date()
    }
}

// MARK: - CloudKit Record Type
extension Quote {
    static let recordType = "Quote"
}
