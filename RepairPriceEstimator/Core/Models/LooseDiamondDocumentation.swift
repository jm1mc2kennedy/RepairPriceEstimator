import Foundation
import CloudKit

/// Diamond shape classifications
enum DiamondShape: String, CaseIterable, Codable, Sendable {
    case round = "RD"
    case princess = "PR"
    case emerald = "EM"
    case oval = "OV"
    case marquise = "MQ"
    case pear = "PS"
    case heart = "HT"
    case radiant = "RA"
    case cushion = "CU"
    case asscher = "AS"
    case other = "OT"
    
    var displayName: String {
        switch self {
        case .round: return "Round"
        case .princess: return "Princess"
        case .emerald: return "Emerald"
        case .oval: return "Oval"
        case .marquise: return "Marquise"
        case .pear: return "Pear"
        case .heart: return "Heart"
        case .radiant: return "Radiant"
        case .cushion: return "Cushion"
        case .asscher: return "Asscher"
        case .other: return "Other"
        }
    }
}

/// Diamond color grades
enum DiamondColor: String, CaseIterable, Codable, Sendable {
    case D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z
    
    var category: String {
        switch self {
        case .D, .E, .F: return "Colorless"
        case .G, .H, .I, .J: return "Near Colorless"
        case .K, .L, .M: return "Faint"
        case .N, .O, .P, .Q, .R: return "Very Light"
        case .S, .T, .U, .V, .W, .X, .Y, .Z: return "Light"
        }
    }
}

/// Diamond clarity grades
enum DiamondClarity: String, CaseIterable, Codable, Sendable {
    case FL = "FL"       // Flawless
    case IF = "IF"       // Internally Flawless
    case VVS1 = "VVS1"   // Very Very Slightly Included 1
    case VVS2 = "VVS2"   // Very Very Slightly Included 2
    case VS1 = "VS1"     // Very Slightly Included 1
    case VS2 = "VS2"     // Very Slightly Included 2
    case SI1 = "SI1"     // Slightly Included 1
    case SI2 = "SI2"     // Slightly Included 2
    case I1 = "I1"       // Included 1
    case I2 = "I2"       // Included 2
    case I3 = "I3"       // Included 3
    
    var displayName: String {
        switch self {
        case .FL: return "Flawless (FL)"
        case .IF: return "Internally Flawless (IF)"
        case .VVS1: return "VVS1"
        case .VVS2: return "VVS2"
        case .VS1: return "VS1"
        case .VS2: return "VS2"
        case .SI1: return "SI1"
        case .SI2: return "SI2"
        case .I1: return "Included 1 (I1)"
        case .I2: return "Included 2 (I2)"
        case .I3: return "Included 3 (I3)"
        }
    }
}

/// Diamond origin classification
enum DiamondOrigin: String, CaseIterable, Codable, Sendable {
    case natural = "NATURAL"
    case labGrown = "LAB_GROWN"
    case simulant = "SIMULANT"
    case unknown = "UNKNOWN"
    
    var displayName: String {
        switch self {
        case .natural: return "Natural"
        case .labGrown: return "Lab Grown"
        case .simulant: return "Simulant"
        case .unknown: return "Unknown"
        }
    }
    
    var abbreviation: String {
        switch self {
        case .natural: return "N"
        case .labGrown: return "LG"
        case .simulant: return "SIM"
        case .unknown: return "?"
        }
    }
}

/// Comprehensive loose diamond documentation
struct LooseDiamondDocumentation: Identifiable, Codable, Sendable {
    let id: String
    let quoteId: String
    let lineItemId: String?
    let documentedBy: String // User ID
    let documentedAt: Date
    
    // Physical characteristics
    let shape: DiamondShape
    let caratWeight: Decimal
    let color: DiamondColor?
    let clarity: DiamondClarity?
    let origin: DiamondOrigin
    
    // Measurements
    let lengthMM: Decimal?
    let widthMM: Decimal?
    let depthMM: Decimal?
    let tablePercentage: Decimal?
    let depthPercentage: Decimal?
    
    // Identification
    let laserInscription: String?
    let certificationNumber: String?
    let certificationLab: String?
    let girdleDescription: String?
    let fluorescence: String?
    
    // Valuation
    let estimatedValue: Decimal?
    let replacementValue: Decimal?
    let appraisalRequired: Bool
    
    // Verification
    let weightVerified: Bool
    let measurementsVerified: Bool
    let inscriptionVerified: Bool
    let verificationNotes: String?
    
    // Photos
    let photoIds: [String]
    
    init(
        id: String = UUID().uuidString,
        quoteId: String,
        lineItemId: String? = nil,
        documentedBy: String,
        documentedAt: Date = Date(),
        shape: DiamondShape,
        caratWeight: Decimal,
        color: DiamondColor? = nil,
        clarity: DiamondClarity? = nil,
        origin: DiamondOrigin = .unknown,
        lengthMM: Decimal? = nil,
        widthMM: Decimal? = nil,
        depthMM: Decimal? = nil,
        tablePercentage: Decimal? = nil,
        depthPercentage: Decimal? = nil,
        laserInscription: String? = nil,
        certificationNumber: String? = nil,
        certificationLab: String? = nil,
        girdleDescription: String? = nil,
        fluorescence: String? = nil,
        estimatedValue: Decimal? = nil,
        replacementValue: Decimal? = nil,
        appraisalRequired: Bool = false,
        weightVerified: Bool = false,
        measurementsVerified: Bool = false,
        inscriptionVerified: Bool = false,
        verificationNotes: String? = nil,
        photoIds: [String] = []
    ) {
        self.id = id
        self.quoteId = quoteId
        self.lineItemId = lineItemId
        self.documentedBy = documentedBy
        self.documentedAt = documentedAt
        self.shape = shape
        self.caratWeight = caratWeight
        self.color = color
        self.clarity = clarity
        self.origin = origin
        self.lengthMM = lengthMM
        self.widthMM = widthMM
        self.depthMM = depthMM
        self.tablePercentage = tablePercentage
        self.depthPercentage = depthPercentage
        self.laserInscription = laserInscription
        self.certificationNumber = certificationNumber
        self.certificationLab = certificationLab
        self.girdleDescription = girdleDescription
        self.fluorescence = fluorescence
        self.estimatedValue = estimatedValue
        self.replacementValue = replacementValue
        self.appraisalRequired = appraisalRequired
        self.weightVerified = weightVerified
        self.measurementsVerified = measurementsVerified
        self.inscriptionVerified = inscriptionVerified
        self.verificationNotes = verificationNotes
        self.photoIds = photoIds
    }
    
    /// Standard diamond description format
    var standardDescription: String {
        var components: [String] = []
        
        // Shape
        components.append(shape.rawValue)
        
        // Carat weight
        components.append("\(caratWeight)ct")
        
        // Color
        if let color = color {
            components.append(color.rawValue)
        }
        
        // Clarity
        if let clarity = clarity {
            components.append(clarity.rawValue)
        }
        
        // Origin
        if origin != .unknown {
            components.append("(\(origin.abbreviation))")
        }
        
        return components.joined(separator: " ")
    }
    
    /// Whether all critical information is documented
    var isCompleteDocumentation: Bool {
        caratWeight > 0 &&
        lengthMM != nil &&
        widthMM != nil &&
        weightVerified &&
        measurementsVerified
    }
    
    /// Whether verification is complete
    var isVerificationComplete: Bool {
        weightVerified &&
        measurementsVerified &&
        (laserInscription == nil || inscriptionVerified)
    }
    
    /// Formatted carat weight display
    var formattedCaratWeight: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 3
        return "\(formatter.string(from: caratWeight as NSDecimalNumber) ?? "\(caratWeight)")ct"
    }
    
    /// Formatted measurements display
    var formattedMeasurements: String? {
        guard let length = lengthMM,
              let width = widthMM else { return nil }
        
        if let depth = depthMM {
            return "\(length) × \(width) × \(depth) mm"
        } else {
            return "\(length) × \(width) mm"
        }
    }
}

// MARK: - CloudKit Record Type
extension LooseDiamondDocumentation {
    static let recordType = "LooseDiamondDocumentation"
}
