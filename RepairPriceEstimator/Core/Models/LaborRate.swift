import Foundation
import CloudKit

/// Represents labor rates for different roles
struct LaborRate: Identifiable, Codable, Sendable {
    let id: String
    let companyId: String
    let role: UserRole
    let ratePerHour: Decimal
    let effectiveDate: Date
    let createdAt: Date
    let isActive: Bool
    
    init(
        id: String = UUID().uuidString,
        companyId: String,
        role: UserRole,
        ratePerHour: Decimal,
        effectiveDate: Date = Date(),
        createdAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.companyId = companyId
        self.role = role
        self.ratePerHour = ratePerHour
        self.effectiveDate = effectiveDate
        self.createdAt = createdAt
        self.isActive = isActive
    }
    
    /// Formatted display of the hourly rate
    var formattedRate: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: ratePerHour as NSDecimalNumber) ?? "$\(ratePerHour)"
    }
    
    /// Full display string including role and rate
    var displayString: String {
        "\(role.rawValue): \(formattedRate)/hour"
    }
    
    /// Calculate cost for given minutes of labor
    func calculateCost(minutes: Int) -> Decimal {
        let hours = Decimal(minutes) / 60
        return hours * ratePerHour
    }
}

// MARK: - CloudKit Record Type
extension LaborRate {
    static let recordType = "LaborRate"
}
