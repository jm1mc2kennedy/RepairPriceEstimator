import Foundation
import SwiftUI

/// ViewModel for managing metal market rates
@MainActor
final class MetalRatesViewModel: ObservableObject {
    nonisolated(unsafe) private let repository: DataRepository
    private let authService: AuthService
    
    @Published var metalRates: [MetalMarketRate] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    init(repository: DataRepository = CloudKitService.shared, authService: AuthService = AuthService.shared) {
        self.repository = repository
        self.authService = authService
    }
    
    func loadMetalRates() async {
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
            let allRates = try await repository.query(MetalMarketRate.self, predicate: predicate, sortDescriptors: sortDescriptors)
            
            // Get the most recent rate for each metal type
            var latestRates: [MetalType: MetalMarketRate] = [:]
            for rate in allRates {
                if let existing = latestRates[rate.metalType] {
                    if rate.effectiveDate > existing.effectiveDate {
                        latestRates[rate.metalType] = rate
                    }
                } else {
                    latestRates[rate.metalType] = rate
                }
            }
            
            metalRates = Array(latestRates.values).sorted { $0.metalType.rawValue < $1.metalType.rawValue }
            print("✅ Loaded \(metalRates.count) metal rate(s)")
        } catch {
            print("❌ Error loading metal rates: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func updateMetalRate(metalType: MetalType, rate: Decimal, unit: MetalUnit = .gramsPerGram) async throws -> MetalMarketRate {
        guard let session = authService.currentSession else {
            throw MetalRateError.notAuthenticated
        }
        
        let newRate = MetalMarketRate(
            companyId: session.company.id,
            metalType: metalType,
            unit: unit,
            rate: rate,
            effectiveDate: Date(),
            isActive: true
        )
        
        let savedRate = try await repository.save(newRate)
        
        // Update in local array
        if let index = metalRates.firstIndex(where: { $0.metalType == metalType }) {
            metalRates[index] = savedRate
        } else {
            metalRates.append(savedRate)
        }
        
        metalRates.sort { $0.metalType.rawValue < $1.metalType.rawValue }
        
        return savedRate
    }
    
    func refresh() async {
        await loadMetalRates()
    }
}

enum MetalRateError: LocalizedError {
    case notAuthenticated
    case invalidRate
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to update metal rates"
        case .invalidRate:
            return "Invalid rate value"
        }
    }
}

