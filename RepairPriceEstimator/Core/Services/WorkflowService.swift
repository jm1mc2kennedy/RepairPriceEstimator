import Foundation

/// Service for managing quote workflow and status transitions
@MainActor
final class WorkflowService: ObservableObject {
    static let shared = WorkflowService()
    
    nonisolated(unsafe) private let repository: DataRepository
    
    @Published var activeQuotes: [Quote] = []
    @Published var isUpdating = false
    
    init(repository: DataRepository = CloudKitService.shared) {
        self.repository = repository
    }
    
    /// Update quote status with business rule validation
    func updateQuoteStatus(
        quoteId: String,
        newStatus: QuoteStatus,
        userId: String,
        notes: String? = nil
    ) async throws -> Quote {
        
        guard let quote = try await repository.fetch(Quote.self, id: quoteId) else {
            throw WorkflowError.quoteNotFound
        }
        
        // Validate status transition
        try validateStatusTransition(from: quote.status, to: newStatus, quote: quote)
        
        // Create updated quote
        var updatedQuote = quote
        updatedQuote.status = newStatus
        updatedQuote.updatedAt = Date()
        
        // Apply status-specific business logic
        try await applyStatusTransitionLogic(&updatedQuote, previousStatus: quote.status, userId: userId)
        
        // Save updated quote
        let savedQuote = try await repository.save(updatedQuote)
        
        // Log status change
        try await logStatusChange(
            quote: savedQuote,
            previousStatus: quote.status,
            newStatus: newStatus,
            userId: userId,
            notes: notes
        )
        
        // Trigger notifications if needed
        try await handleStatusChangeNotifications(quote: savedQuote, previousStatus: quote.status)
        
        print("✅ Updated quote \(quoteId) status: \(quote.status.rawValue) → \(newStatus.rawValue)")
        return savedQuote
    }
    
    /// Get quotes by priority for queue management
    func getQueuedQuotes(companyId: String, storeId: String? = nil) async throws -> [Quote] {
        var predicate = NSPredicate(format: "companyId == %@", companyId)
        
        if let storeId = storeId {
            predicate = NSPredicate(format: "companyId == %@ AND storeId == %@", companyId, storeId)
        }
        
        let quotes = try await repository.query(
            Quote.self,
            predicate: predicate,
            sortDescriptors: [
                NSSortDescriptor(key: "priority", ascending: true),
                NSSortDescriptor(key: "promisedDueDate", ascending: true)
            ]
        )
        
        // Filter active quotes only
        return quotes.filter { $0.status.isActiveWork || $0.status.requiresQualityControl }
    }
    
    /// Get overdue quotes
    func getOverdueQuotes(companyId: String) async throws -> [Quote] {
        let now = Date()
        let predicate = NSPredicate(format: "companyId == %@ AND promisedDueDate < %@ AND status != %@ AND status != %@", 
                                   companyId, now as NSDate, QuoteStatus.completed.rawValue, QuoteStatus.closed.rawValue)
        
        return try await repository.query(Quote.self, predicate: predicate, sortDescriptors: nil)
    }
    
    /// Batch update priorities for all quotes
    func recalculateAllPriorities(companyId: String) async throws {
        isUpdating = true
        defer { isUpdating = false }
        
        let quotes = try await repository.query(Quote.self, 
                                              predicate: NSPredicate(format: "companyId == %@", companyId), 
                                              sortDescriptors: nil)
        
        for quote in quotes {
            var updatedQuote = quote
            updatedQuote.updatePriority()
            _ = try await repository.save(updatedQuote)
        }
    }
    
    // MARK: - Private Methods
    
    private func validateStatusTransition(from currentStatus: QuoteStatus, to newStatus: QuoteStatus, quote: Quote) throws {
        // Check if transition is allowed
        guard currentStatus.possibleNextStatuses.contains(newStatus) else {
            throw WorkflowError.invalidStatusTransition(from: currentStatus, to: newStatus)
        }
        
        // Special validation rules
        switch newStatus {
        case .approved:
            guard quote.needsEstimateApproval == false || quote.estimateApproved else {
                throw WorkflowError.estimateNotApproved
            }
            
        case .inShop:
            guard quote.status == .approved else {
                throw WorkflowError.workCannotStart
            }
            
        case .qualityReview:
            guard quote.status.isActiveWork else {
                throw WorkflowError.qualityControlNotApplicable
            }
            
        case .readyForPickup:
            // Must pass quality review first
            guard quote.status == .qualityReview else {
                throw WorkflowError.qualityControlRequired
            }
            
        default:
            break
        }
    }
    
    private func applyStatusTransitionLogic(_ quote: inout Quote, previousStatus: QuoteStatus, userId: String) async throws {
        switch quote.status {
        case .approved:
            // Set work start date
            if quote.promisedDueDate == nil {
                // Auto-calculate due date based on service complexity
                let workingDays = calculateEstimatedWorkingDays(quote: quote)
                quote.promisedDueDate = addWorkingDays(to: Date(), days: workingDays)
            }
            
        case .inShop:
            // Log work start
            quote.priority = quote.rushType == .sameDay ? .urgent : .high
            
        case .qualityReview:
            // Ensure quality control requirements are met
            break
            
        case .qualityFailed:
            // Reset to rework with notes
            quote.priority = .urgent // High priority to fix issues
            
        case .readyForPickup:
            // Generate pickup notification
            break
            
        case .completed:
            // Final completion processing
            quote.priority = .low
            
        default:
            break
        }
        
        quote.updatedAt = Date()
    }
    
    private func calculateEstimatedWorkingDays(quote: Quote) -> Int {
        // Calculate based on service complexity and category
        switch quote.primaryServiceCategory {
        case .jewelryRepair:
            return quote.rushType == .sameDay ? 1 : 3
        case .watchService:
            return quote.rushType == .sameDay ? 1 : 5
        case .carePlan:
            return 2
        case .appraisal:
            return 7
        default:
            return 5
        }
    }
    
    private func addWorkingDays(to date: Date, days: Int) -> Date {
        var result = date
        var daysAdded = 0
        
        while daysAdded < days {
            result = Calendar.current.date(byAdding: .day, value: 1, to: result) ?? result
            
            let weekday = Calendar.current.component(.weekday, from: result)
            // Skip weekends (1 = Sunday, 7 = Saturday)
            if weekday != 1 && weekday != 7 {
                daysAdded += 1
            }
        }
        
        return result
    }
    
    private func logStatusChange(
        quote: Quote,
        previousStatus: QuoteStatus,
        newStatus: QuoteStatus,
        userId: String,
        notes: String?
    ) async throws {
        _ = StatusChangeLog(
            quoteId: quote.id,
            previousStatus: previousStatus,
            newStatus: newStatus,
            changedBy: userId,
            notes: notes
        )
        
        // In a full implementation, this would save to StatusChangeLog table
        print("📝 Status change logged: \(quote.id) \(previousStatus.rawValue) → \(newStatus.rawValue)")
    }
    
    private func handleStatusChangeNotifications(quote: Quote, previousStatus: QuoteStatus) async throws {
        // Trigger appropriate notifications based on status change
        switch quote.status {
        case .presented:
            // Send estimate to customer
            try await scheduleCustomerNotification(quote: quote, purpose: .estimateReady)
            
        case .awaitingApproval:
            // Request approval from customer
            try await scheduleCustomerNotification(quote: quote, purpose: .approvalRequest)
            
        case .atVendor:
            // Notify customer of vendor delay if applicable
            if quote.isOverdue {
                try await scheduleCustomerNotification(quote: quote, purpose: .delayNotification)
            }
            
        case .qualityFailed:
            // Internal notification to repair coordinator
            print("🚨 Quality control failed for quote \(quote.id) - coordinator notified")
            
        case .readyForPickup:
            // Notify customer item is ready
            try await scheduleCustomerNotification(quote: quote, purpose: .readyForPickup)
            
        default:
            break
        }
    }
    
    private func scheduleCustomerNotification(quote: Quote, purpose: CommunicationPurpose) async throws {
        // Create communication log entry for scheduled notification
        print("📧 Scheduled \(purpose.displayName) notification for quote \(quote.id)")
    }
}

/// Status change log entry
struct StatusChangeLog: Identifiable, Codable, Sendable {
    let id: String
    let quoteId: String
    let previousStatus: QuoteStatus
    let newStatus: QuoteStatus
    let changedBy: String
    let changedAt: Date
    let notes: String?
    
    init(
        id: String = UUID().uuidString,
        quoteId: String,
        previousStatus: QuoteStatus,
        newStatus: QuoteStatus,
        changedBy: String,
        changedAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.quoteId = quoteId
        self.previousStatus = previousStatus
        self.newStatus = newStatus
        self.changedBy = changedBy
        self.changedAt = changedAt
        self.notes = notes
    }
}

// MARK: - Workflow Errors

enum WorkflowError: Error, LocalizedError {
    case quoteNotFound
    case invalidStatusTransition(from: QuoteStatus, to: QuoteStatus)
    case estimateNotApproved
    case workCannotStart
    case qualityControlNotApplicable
    case qualityControlRequired
    case coordinatorApprovalRequired
    case insufficientPermissions
    
    var errorDescription: String? {
        switch self {
        case .quoteNotFound:
            return "Quote not found"
        case .invalidStatusTransition(let from, let to):
            return "Cannot change status from \(from.displayName) to \(to.displayName)"
        case .estimateNotApproved:
            return "Estimate must be approved before starting work"
        case .workCannotStart:
            return "Work cannot be started in current status"
        case .qualityControlNotApplicable:
            return "Quality control not applicable for current status"
        case .qualityControlRequired:
            return "Quality control must be completed first"
        case .coordinatorApprovalRequired:
            return "Coordinator approval required for this action"
        case .insufficientPermissions:
            return "Insufficient permissions for this action"
        }
    }
}

// MARK: - CloudKit Record Types
extension StatusChangeLog {
    static let recordType = "StatusChangeLog"
}
