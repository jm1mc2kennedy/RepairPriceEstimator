import Foundation
import SwiftUI

/// ViewModel for managing labor rates
@MainActor
final class LaborRatesViewModel: ObservableObject {
    nonisolated(unsafe) private let repository: DataRepository
    private let authService: AuthService
    
    @Published var laborRates: [LaborRate] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    init(repository: DataRepository = CloudKitService.shared, authService: AuthService = AuthService.shared) {
        self.repository = repository
        self.authService = authService
    }
    
    func loadLaborRates() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let session = authService.currentSession else {
            errorMessage = "Not authenticated"
            showError = true
            return
        }
        
        do {
            let predicate = NSPredicate(format: "companyId == %@ AND isActive == 1", session.company.id)
            let sortDescriptors = [NSSortDescriptor(key: "effectiveDate", ascending: false)]
            let allRates = try await repository.query(LaborRate.self, predicate: predicate, sortDescriptors: sortDescriptors)
            
            // Get the most recent rate for each role
            var latestRates: [UserRole: LaborRate] = [:]
            for rate in allRates {
                if let existing = latestRates[rate.role] {
                    if rate.effectiveDate > existing.effectiveDate {
                        latestRates[rate.role] = rate
                    }
                } else {
                    latestRates[rate.role] = rate
                }
            }
            
            laborRates = Array(latestRates.values).sorted { $0.role.rawValue < $1.role.rawValue }
            print("✅ Loaded \(laborRates.count) labor rate(s)")
        } catch {
            print("❌ Error loading labor rates: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func updateLaborRate(role: UserRole, ratePerHour: Decimal) async throws -> LaborRate {
        guard let session = authService.currentSession else {
            throw LaborRateError.notAuthenticated
        }
        
        let newRate = LaborRate(
            companyId: session.company.id,
            role: role,
            ratePerHour: ratePerHour,
            effectiveDate: Date(),
            isActive: true
        )
        
        let savedRate = try await repository.save(newRate)
        
        // Update in local array
        if let index = laborRates.firstIndex(where: { $0.role == role }) {
            laborRates[index] = savedRate
        } else {
            laborRates.append(savedRate)
        }
        
        laborRates.sort { $0.role.rawValue < $1.role.rawValue }
        
        return savedRate
    }
    
    func refresh() async {
        await loadLaborRates()
    }
}

enum LaborRateError: LocalizedError {
    case notAuthenticated
    case invalidRate
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to update labor rates"
        case .invalidRate:
            return "Invalid rate value"
        }
    }
}

