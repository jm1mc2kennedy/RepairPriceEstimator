import Foundation
import CloudKit

/// Represents a guest/customer in the system
struct Guest: Identifiable, Codable, Sendable {
    let id: String
    let companyId: String
    let primaryStoreId: String
    let firstName: String
    let lastName: String
    let email: String?
    let phone: String?
    let notes: String?
    
    init(
        id: String = UUID().uuidString,
        companyId: String,
        primaryStoreId: String,
        firstName: String,
        lastName: String,
        email: String? = nil,
        phone: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.companyId = companyId
        self.primaryStoreId = primaryStoreId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.notes = notes
    }
    
    /// Returns the full name of the guest
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    /// Returns display contact info (email or phone)
    var contactInfo: String? {
        email ?? phone
    }
}

// MARK: - CloudKit Record Type
extension Guest {
    static let recordType = "Guest"
}
