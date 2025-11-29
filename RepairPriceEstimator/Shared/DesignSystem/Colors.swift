import SwiftUI

/// App-wide color scheme and design tokens
extension Color {
    
    // MARK: - Primary Colors
    static let primaryBlue = Color(red: 0.2, green: 0.4, blue: 0.8)
    static let primaryDark = Color(red: 0.1, green: 0.2, blue: 0.4)
    static let primaryLight = Color(red: 0.8, green: 0.85, blue: 0.95)
    
    // MARK: - Accent Colors
    static let accentGold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let accentSilver = Color(red: 0.75, green: 0.75, blue: 0.75)
    static let accentGreen = Color(red: 0.2, green: 0.8, blue: 0.2)
    static let accentRed = Color(red: 0.8, green: 0.2, blue: 0.2)
    
    // MARK: - Background Colors
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    
    // MARK: - Text Colors
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    
    // MARK: - Status Colors
    static let statusDraft = Color(.systemGray)
    static let statusPresented = Color(.systemBlue)
    static let statusApproved = Color(.systemGreen)
    static let statusDeclined = Color(.systemRed)
    static let statusInProgress = Color(.systemOrange)
    static let statusCompleted = Color(.systemPurple)
    static let statusClosed = Color(.systemGray2)
    
    // MARK: - Rush Colors
    static let rushIndicator = Color(.systemOrange)
    static let rushBackground = Color(.systemOrange).opacity(0.1)
    
    // MARK: - Card Colors
    static let cardBackground = Color(.secondarySystemBackground)
    static let cardBorder = Color(.separator)
}

// MARK: - Quote Status Colors
extension QuoteStatus {
    var color: Color {
        switch self {
        case .draft: return .statusDraft
        case .presented: return .statusPresented
        case .awaitingApproval: return .statusPresented
        case .approved: return .statusApproved
        case .declined: return .statusDeclined
        case .inShop: return .statusInProgress
        case .atVendor: return .statusInProgress
        case .qualityReview: return .statusInProgress
        case .qualityFailed: return .statusDeclined
        case .rework: return .statusInProgress
        case .readyForPickup: return .statusApproved
        case .completed: return .statusCompleted
        case .closed: return .statusClosed
        case .cancelled: return .statusDeclined
        }
    }
}

// MARK: - Service Category Colors
extension ServiceCategory {
    var color: Color {
        switch self {
        case .jewelryRepair: return .accentGold
        case .watchService: return .primaryBlue
        case .carePlan: return .accentGreen
        case .estateLiquidation: return .textTertiary
        case .appraisal: return .primaryDark
        case .cleaning: return .accentGreen
        case .customDesign: return .accentSilver
        case .engraving: return .textSecondary
        case .other: return .textTertiary
        }
    }
}
