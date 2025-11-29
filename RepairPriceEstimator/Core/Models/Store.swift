import Foundation
import CloudKit

/// Represents a store entity within a company
struct Store: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let companyId: String
    let name: String
    let storeCode: String
    let location: String
    let phone: String
    let isActive: Bool
    
    init(
        id: String = UUID().uuidString,
        companyId: String,
        name: String,
        storeCode: String,
        location: String,
        phone: String,
        isActive: Bool = true
    ) {
        self.id = id
        self.companyId = companyId
        self.name = name
        self.storeCode = storeCode
        self.location = location
        self.phone = phone
        self.isActive = isActive
    }
}

// MARK: - CloudKit Record Type
extension Store {
    static let recordType = "Store"
}
