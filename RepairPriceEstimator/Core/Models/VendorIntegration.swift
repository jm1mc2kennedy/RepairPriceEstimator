import Foundation
import CloudKit

/// Types of vendor services
enum VendorServiceType: String, CaseIterable, Codable, Sendable {
    case watchRepair = "WATCH_REPAIR"
    case watchService = "WATCH_SERVICE"
    case jewelryRepair = "JEWELRY_REPAIR"
    case appraisal = "APPRAISAL"
    case stoneReplacement = "STONE_REPLACEMENT"
    case engraving = "ENGRAVING"
    case customManufacturing = "CUSTOM_MANUFACTURING"
    case refinishing = "REFINISHING"
    case certification = "CERTIFICATION"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .watchRepair: return "Watch Repair"
        case .watchService: return "Watch Service"
        case .jewelryRepair: return "Jewelry Repair"
        case .appraisal: return "Appraisal Services"
        case .stoneReplacement: return "Stone Replacement"
        case .engraving: return "Engraving"
        case .customManufacturing: return "Custom Manufacturing"
        case .refinishing: return "Refinishing"
        case .certification: return "Certification"
        case .other: return "Other Services"
        }
    }
}

/// Vendor specialization areas
enum VendorSpecialization: String, CaseIterable, Codable, Sendable {
    // Watch brands
    case rolex = "ROLEX"
    case omega = "OMEGA"
    case tagHeuer = "TAG_HEUER"
    case breitling = "BREITLING"
    case cartier = "CARTIER"
    case genericWatch = "GENERIC_WATCH"
    
    // Jewelry specializations
    case diamondSetting = "DIAMOND_SETTING"
    case pearlRestringing = "PEARL_RESTRINGING"
    case antiqueRestoration = "ANTIQUE_RESTORATION"
    case customDesign = "CUSTOM_DESIGN"
    case chainRepair = "CHAIN_REPAIR"
    
    // Specialized services
    case gemCertification = "GEM_CERTIFICATION"
    case appraisals = "APPRAISALS"
    case engraving = "ENGRAVING"
    case castingServices = "CASTING_SERVICES"
    
    var displayName: String {
        switch self {
        case .rolex: return "Rolex"
        case .omega: return "Omega"
        case .tagHeuer: return "TAG Heuer"
        case .breitling: return "Breitling"
        case .cartier: return "Cartier"
        case .genericWatch: return "Generic Watch"
        case .diamondSetting: return "Diamond Setting"
        case .pearlRestringing: return "Pearl Restringing"
        case .antiqueRestoration: return "Antique Restoration"
        case .customDesign: return "Custom Design"
        case .chainRepair: return "Chain Repair"
        case .gemCertification: return "Gem Certification"
        case .appraisals: return "Appraisals"
        case .engraving: return "Engraving"
        case .castingServices: return "Casting Services"
        }
    }
}

/// Vendor information and capabilities
struct Vendor: Identifiable, Codable, Sendable {
    let id: String
    let companyId: String
    let name: String
    let businessName: String?
    
    // Contact information
    let contactPerson: String?
    let phone: String?
    let email: String?
    let address: String?
    let website: String?
    
    // Service capabilities
    let serviceTypes: [VendorServiceType]
    let specializations: [VendorSpecialization]
    let supportedBrands: [String] // Additional brands not in enum
    
    // Business terms
    let typicalTurnaroundDays: Int
    let rushAvailable: Bool
    let rushTurnaroundDays: Int?
    let minimumOrder: Decimal?
    let paymentTerms: String?
    let shippingPolicy: String?
    
    // Performance metrics
    let qualityRating: Decimal // 1-5 scale
    let reliabilityRating: Decimal // 1-5 scale
    let communicationRating: Decimal // 1-5 scale
    let preferredVendor: Bool
    
    // Status
    let isActive: Bool
    let notes: String?
    let lastUsedDate: Date?
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        companyId: String,
        name: String,
        businessName: String? = nil,
        contactPerson: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        address: String? = nil,
        website: String? = nil,
        serviceTypes: [VendorServiceType] = [],
        specializations: [VendorSpecialization] = [],
        supportedBrands: [String] = [],
        typicalTurnaroundDays: Int = 14,
        rushAvailable: Bool = false,
        rushTurnaroundDays: Int? = nil,
        minimumOrder: Decimal? = nil,
        paymentTerms: String? = nil,
        shippingPolicy: String? = nil,
        qualityRating: Decimal = 0,
        reliabilityRating: Decimal = 0,
        communicationRating: Decimal = 0,
        preferredVendor: Bool = false,
        isActive: Bool = true,
        notes: String? = nil,
        lastUsedDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.companyId = companyId
        self.name = name
        self.businessName = businessName
        self.contactPerson = contactPerson
        self.phone = phone
        self.email = email
        self.address = address
        self.website = website
        self.serviceTypes = serviceTypes
        self.specializations = specializations
        self.supportedBrands = supportedBrands
        self.typicalTurnaroundDays = typicalTurnaroundDays
        self.rushAvailable = rushAvailable
        self.rushTurnaroundDays = rushTurnaroundDays
        self.minimumOrder = minimumOrder
        self.paymentTerms = paymentTerms
        self.shippingPolicy = shippingPolicy
        self.qualityRating = qualityRating
        self.reliabilityRating = reliabilityRating
        self.communicationRating = communicationRating
        self.preferredVendor = preferredVendor
        self.isActive = isActive
        self.notes = notes
        self.lastUsedDate = lastUsedDate
        self.createdAt = createdAt
    }
    
    /// Overall vendor rating (average of quality, reliability, communication)
    var overallRating: Decimal {
        (qualityRating + reliabilityRating + communicationRating) / 3
    }
    
    /// Whether vendor can handle rush orders
    var canRush: Bool {
        rushAvailable && rushTurnaroundDays != nil
    }
    
    /// Display name for vendor
    var displayName: String {
        businessName ?? name
    }
}

/// Vendor work order tracking
struct VendorWorkOrder: Identifiable, Codable, Sendable {
    let id: String
    let quoteId: String
    let vendorId: String
    let serviceType: VendorServiceType
    
    // Order details
    let description: String
    let specialInstructions: String?
    let vendorSku: String?
    let vendorInvoiceNumber: String?
    
    // Pricing
    let estimatedCost: Decimal?
    let actualCost: Decimal?
    let markup: Decimal // Markup percentage
    let finalPrice: Decimal?
    
    // Timing
    let dateOrdered: Date
    let estimatedCompletion: Date
    let actualCompletion: Date?
    let isRush: Bool
    
    // Status tracking
    let status: VendorWorkOrderStatus
    let trackingNumber: String?
    let shippingMethod: String?
    
    // Communication
    let lastVendorContact: Date?
    let vendorNotes: String?
    let internalNotes: String?
    
    init(
        id: String = UUID().uuidString,
        quoteId: String,
        vendorId: String,
        serviceType: VendorServiceType,
        description: String,
        specialInstructions: String? = nil,
        vendorSku: String? = nil,
        vendorInvoiceNumber: String? = nil,
        estimatedCost: Decimal? = nil,
        actualCost: Decimal? = nil,
        markup: Decimal = 50, // Default 50% markup
        finalPrice: Decimal? = nil,
        dateOrdered: Date = Date(),
        estimatedCompletion: Date,
        actualCompletion: Date? = nil,
        isRush: Bool = false,
        status: VendorWorkOrderStatus = .ordered,
        trackingNumber: String? = nil,
        shippingMethod: String? = nil,
        lastVendorContact: Date? = nil,
        vendorNotes: String? = nil,
        internalNotes: String? = nil
    ) {
        self.id = id
        self.quoteId = quoteId
        self.vendorId = vendorId
        self.serviceType = serviceType
        self.description = description
        self.specialInstructions = specialInstructions
        self.vendorSku = vendorSku
        self.vendorInvoiceNumber = vendorInvoiceNumber
        self.estimatedCost = estimatedCost
        self.actualCost = actualCost
        self.markup = markup
        self.finalPrice = finalPrice
        self.dateOrdered = dateOrdered
        self.estimatedCompletion = estimatedCompletion
        self.actualCompletion = actualCompletion
        self.isRush = isRush
        self.status = status
        self.trackingNumber = trackingNumber
        self.shippingMethod = shippingMethod
        self.lastVendorContact = lastVendorContact
        self.vendorNotes = vendorNotes
        self.internalNotes = internalNotes
    }
    
    /// Whether the work order is overdue
    var isOverdue: Bool {
        guard actualCompletion == nil else { return false }
        return estimatedCompletion < Date()
    }
    
    /// Days until completion (negative if overdue)
    var daysUntilCompletion: Int {
        let targetDate = actualCompletion ?? estimatedCompletion
        return Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
    }
}

/// Status of vendor work orders
enum VendorWorkOrderStatus: String, CaseIterable, Codable, Sendable {
    case ordered = "ORDERED"
    case inProgress = "IN_PROGRESS"
    case shipped = "SHIPPED"
    case received = "RECEIVED"
    case qualityCheck = "QUALITY_CHECK"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
    case delayed = "DELAYED"
    case onHold = "ON_HOLD"
    
    var displayName: String {
        switch self {
        case .ordered: return "Ordered"
        case .inProgress: return "In Progress"
        case .shipped: return "Shipped"
        case .received: return "Received"
        case .qualityCheck: return "Quality Check"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .delayed: return "Delayed"
        case .onHold: return "On Hold"
        }
    }
    
    var color: String {
        switch self {
        case .ordered, .inProgress: return "blue"
        case .shipped, .received: return "orange"
        case .qualityCheck: return "yellow"
        case .completed: return "green"
        case .cancelled: return "gray"
        case .delayed: return "red"
        case .onHold: return "purple"
        }
    }
}

// MARK: - CloudKit Record Types
extension Vendor {
    static let recordType = "Vendor"
}

extension VendorWorkOrder {
    static let recordType = "VendorWorkOrder"
}
