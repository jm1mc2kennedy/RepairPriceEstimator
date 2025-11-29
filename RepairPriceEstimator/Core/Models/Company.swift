import Foundation
import CloudKit

/// Represents a company entity in the repair price estimator system
struct Company: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let primaryContactInfo: String
    let createdAt: Date
    
    init(id: String = UUID().uuidString, name: String, primaryContactInfo: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.primaryContactInfo = primaryContactInfo
        self.createdAt = createdAt
    }
}

// MARK: - CloudKit Record Type
extension Company {
    static let recordType = "Company"
}
