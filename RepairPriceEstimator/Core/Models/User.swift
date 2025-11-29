import Foundation
import CloudKit

/// User role enumeration for role-based access control
enum UserRole: String, CaseIterable, Codable, Sendable, Identifiable {
    var id: String { rawValue }
    case superAdmin = "SUPERADMIN"
    case admin = "ADMIN"
    case storeManager = "STORE_MANAGER"
    case associate = "ASSOCIATE"
    case benchJeweler = "BENCH_JEWELER"
    
    /// Returns whether this role can access admin features
    var canAccessAdmin: Bool {
        switch self {
        case .superAdmin, .admin:
            return true
        case .storeManager, .associate, .benchJeweler:
            return false
        }
    }
    
    /// Returns whether this role can approve pricing overrides
    var canApproveOverrides: Bool {
        switch self {
        case .superAdmin, .admin, .storeManager:
            return true
        case .associate, .benchJeweler:
            return false
        }
    }
    
    /// User-friendly display name for the role
    var displayName: String {
        switch self {
        case .superAdmin: return "Super Admin"
        case .admin: return "Admin"
        case .storeManager: return "Store Manager"
        case .associate: return "Associate"
        case .benchJeweler: return "Bench Jeweler"
        }
    }
}

/// Represents a user in the system
struct User: Identifiable, Codable, Sendable {
    let id: String
    let companyId: String
    let storeIds: [String]
    let role: UserRole
    let displayName: String
    let email: String
    let isActive: Bool
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        companyId: String,
        storeIds: [String],
        role: UserRole,
        displayName: String,
        email: String,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.companyId = companyId
        self.storeIds = storeIds
        self.role = role
        self.displayName = displayName
        self.email = email
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

// MARK: - CloudKit Record Type
extension User {
    static let recordType = "User"
}
