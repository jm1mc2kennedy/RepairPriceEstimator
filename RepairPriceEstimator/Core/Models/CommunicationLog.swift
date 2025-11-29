import Foundation
import CloudKit

/// Types of communication with clients
enum CommunicationType: String, CaseIterable, Codable, Sendable {
    case phone = "PHONE"
    case email = "EMAIL"
    case text = "TEXT"
    case inPerson = "IN_PERSON"
    case voicemail = "VOICEMAIL"
    case notification = "NOTIFICATION"
    
    var displayName: String {
        switch self {
        case .phone: return "Phone Call"
        case .email: return "Email"
        case .text: return "Text Message"
        case .inPerson: return "In Person"
        case .voicemail: return "Voicemail"
        case .notification: return "System Notification"
        }
    }
    
    var icon: String {
        switch self {
        case .phone: return "phone"
        case .email: return "envelope"
        case .text: return "message"
        case .inPerson: return "person"
        case .voicemail: return "voicemail"
        case .notification: return "bell"
        }
    }
}

/// Direction of communication
enum CommunicationDirection: String, Codable, Sendable {
    case incoming = "INCOMING"
    case outgoing = "OUTGOING"
    
    var displayName: String {
        switch self {
        case .incoming: return "Incoming"
        case .outgoing: return "Outgoing"
        }
    }
}

/// Status of communication
enum CommunicationStatus: String, CaseIterable, Codable, Sendable {
    case sent = "SENT"
    case delivered = "DELIVERED"
    case read = "READ"
    case replied = "REPLIED"
    case failed = "FAILED"
    case pending = "PENDING"
    
    var displayName: String {
        switch self {
        case .sent: return "Sent"
        case .delivered: return "Delivered"
        case .read: return "Read"
        case .replied: return "Replied"
        case .failed: return "Failed"
        case .pending: return "Pending"
        }
    }
}

/// Purpose/context of communication
enum CommunicationPurpose: String, CaseIterable, Codable, Sendable {
    case estimateReady = "ESTIMATE_READY"
    case approvalRequest = "APPROVAL_REQUEST"
    case workInProgress = "WORK_IN_PROGRESS"
    case delayNotification = "DELAY_NOTIFICATION"
    case vendorUpdate = "VENDOR_UPDATE"
    case qualityIssue = "QUALITY_ISSUE"
    case readyForPickup = "READY_FOR_PICKUP"
    case paymentDue = "PAYMENT_DUE"
    case followUp = "FOLLOW_UP"
    case general = "GENERAL"
    
    var displayName: String {
        switch self {
        case .estimateReady: return "Estimate Ready"
        case .approvalRequest: return "Approval Request"
        case .workInProgress: return "Work in Progress"
        case .delayNotification: return "Delay Notification"
        case .vendorUpdate: return "Vendor Update"
        case .qualityIssue: return "Quality Issue"
        case .readyForPickup: return "Ready for Pickup"
        case .paymentDue: return "Payment Due"
        case .followUp: return "Follow Up"
        case .general: return "General"
        }
    }
    
    /// Whether this purpose requires urgent follow-up
    var isUrgent: Bool {
        switch self {
        case .qualityIssue, .delayNotification, .approvalRequest: return true
        case .estimateReady, .readyForPickup, .paymentDue: return true
        case .workInProgress, .vendorUpdate, .followUp, .general: return false
        }
    }
}

/// Communication log entry for tracking all client interactions
struct CommunicationLog: Identifiable, Codable, Sendable {
    let id: String
    let quoteId: String
    let guestId: String
    let userId: String // Staff member who initiated/received the communication
    
    // Communication details
    let type: CommunicationType
    let direction: CommunicationDirection
    let purpose: CommunicationPurpose
    let status: CommunicationStatus
    
    // Content
    let subject: String?
    let message: String
    let clientFacingNotes: String?  // What was communicated to client
    let internalNotes: String?      // Staff notes about the communication
    
    // Timing
    let createdAt: Date
    let scheduledFor: Date?         // For scheduled communications
    let completedAt: Date?          // When communication was completed
    let followUpRequired: Bool
    let followUpDate: Date?
    
    // Metadata
    let attachments: [String]       // File URLs or references
    let relatedQuoteStatus: QuoteStatus?
    let automatedMessage: Bool      // Whether this was sent automatically
    let templateUsed: String?       // Template ID if used
    
    init(
        id: String = UUID().uuidString,
        quoteId: String,
        guestId: String,
        userId: String,
        type: CommunicationType,
        direction: CommunicationDirection,
        purpose: CommunicationPurpose,
        status: CommunicationStatus = .pending,
        subject: String? = nil,
        message: String,
        clientFacingNotes: String? = nil,
        internalNotes: String? = nil,
        createdAt: Date = Date(),
        scheduledFor: Date? = nil,
        completedAt: Date? = nil,
        followUpRequired: Bool = false,
        followUpDate: Date? = nil,
        attachments: [String] = [],
        relatedQuoteStatus: QuoteStatus? = nil,
        automatedMessage: Bool = false,
        templateUsed: String? = nil
    ) {
        self.id = id
        self.quoteId = quoteId
        self.guestId = guestId
        self.userId = userId
        self.type = type
        self.direction = direction
        self.purpose = purpose
        self.status = status
        self.subject = subject
        self.message = message
        self.clientFacingNotes = clientFacingNotes
        self.internalNotes = internalNotes
        self.createdAt = createdAt
        self.scheduledFor = scheduledFor
        self.completedAt = completedAt
        self.followUpRequired = followUpRequired
        self.followUpDate = followUpDate
        self.attachments = attachments
        self.relatedQuoteStatus = relatedQuoteStatus
        self.automatedMessage = automatedMessage
        self.templateUsed = templateUsed
    }
    
    /// Whether this communication is overdue for follow-up
    var isOverdue: Bool {
        guard followUpRequired,
              let followUpDate = followUpDate else { return false }
        return followUpDate < Date() && status != .replied
    }
    
    /// Display summary for timeline views
    var displaySummary: String {
        let prefix = direction == .outgoing ? "→" : "←"
        let typeIcon = type.displayName
        return "\(prefix) \(typeIcon): \(purpose.displayName)"
    }
}

/// Communication template for standard messages
struct CommunicationTemplate: Identifiable, Codable, Sendable {
    let id: String
    let companyId: String
    let name: String
    let purpose: CommunicationPurpose
    let type: CommunicationType
    let subject: String?
    let messageTemplate: String     // Can include variables like {{guestName}}, {{quoteId}}
    let isActive: Bool
    let createdAt: Date
    let lastUsedAt: Date?
    
    init(
        id: String = UUID().uuidString,
        companyId: String,
        name: String,
        purpose: CommunicationPurpose,
        type: CommunicationType,
        subject: String? = nil,
        messageTemplate: String,
        isActive: Bool = true,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.companyId = companyId
        self.name = name
        self.purpose = purpose
        self.type = type
        self.subject = subject
        self.messageTemplate = messageTemplate
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
    
    /// Generate message with variable substitution
    func generateMessage(
        guestName: String,
        quoteId: String,
        estimateAmount: String? = nil,
        dueDate: String? = nil
    ) -> String {
        var message = messageTemplate
        message = message.replacingOccurrences(of: "{{guestName}}", with: guestName)
        message = message.replacingOccurrences(of: "{{quoteId}}", with: quoteId)
        if let estimate = estimateAmount {
            message = message.replacingOccurrences(of: "{{estimateAmount}}", with: estimate)
        }
        if let date = dueDate {
            message = message.replacingOccurrences(of: "{{dueDate}}", with: date)
        }
        return message
    }
}

// MARK: - CloudKit Record Types
extension CommunicationLog {
    static let recordType = "CommunicationLog"
}

extension CommunicationTemplate {
    static let recordType = "CommunicationTemplate"
}
