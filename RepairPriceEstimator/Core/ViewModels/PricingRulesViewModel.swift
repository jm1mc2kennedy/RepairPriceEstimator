import Foundation
import SwiftUI

/// ViewModel for managing pricing rules
@MainActor
final class PricingRulesViewModel: ObservableObject {
    nonisolated(unsafe) private let repository: DataRepository
    private let authService: AuthService
    
    @Published var pricingRules: [PricingRule] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    init(repository: DataRepository = CloudKitService.shared, authService: AuthService = AuthService.shared) {
        self.repository = repository
        self.authService = authService
    }
    
    func loadPricingRules() async {
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
            let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            pricingRules = try await repository.query(PricingRule.self, predicate: predicate, sortDescriptors: sortDescriptors)
            print("✅ Loaded \(pricingRules.count) pricing rule(s)")
        } catch {
            print("❌ Error loading pricing rules: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func updatePricingRule(_ rule: PricingRule) async throws -> PricingRule {
        let updatedRule = try await repository.save(rule)
        
        if let index = pricingRules.firstIndex(where: { $0.id == rule.id }) {
            pricingRules[index] = updatedRule
        } else {
            pricingRules.append(updatedRule)
        }
        
        return updatedRule
    }
    
    func refresh() async {
        await loadPricingRules()
    }
}

