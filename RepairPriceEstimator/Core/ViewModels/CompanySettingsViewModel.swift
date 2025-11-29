import Foundation
import SwiftUI

/// ViewModel for managing company and store settings
@MainActor
final class CompanySettingsViewModel: ObservableObject {
    nonisolated(unsafe) private let repository: DataRepository
    private let authService: AuthService
    
    @Published var company: Company?
    @Published var stores: [Store] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    init(repository: DataRepository = CloudKitService.shared, authService: AuthService = AuthService.shared) {
        self.repository = repository
        self.authService = authService
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let session = authService.currentSession else {
            errorMessage = "Not authenticated"
            showError = true
            return
        }
        
        do {
            company = session.company
            
            let predicate = NSPredicate(format: "companyId == %@", session.company.id)
            let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            stores = try await repository.query(Store.self, predicate: predicate, sortDescriptors: sortDescriptors)
            
            print("✅ Loaded company and \(stores.count) store(s)")
        } catch {
            print("❌ Error loading company settings: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func updateCompany(_ updatedCompany: Company) async throws -> Company {
        let savedCompany = try await repository.save(updatedCompany)
        company = savedCompany
        return savedCompany
    }
    
    func createStore(_ store: Store) async throws -> Store {
        let savedStore = try await repository.save(store)
        stores.append(savedStore)
        stores.sort { $0.name < $1.name }
        return savedStore
    }
    
    func updateStore(_ store: Store) async throws -> Store {
        let updatedStore = try await repository.save(store)
        
        if let index = stores.firstIndex(where: { $0.id == store.id }) {
            stores[index] = updatedStore
        }
        stores.sort { $0.name < $1.name }
        
        return updatedStore
    }
    
    func deleteStore(_ store: Store) async throws {
        // Deactivate store instead of hard delete
        let deactivatedStore = Store(
            id: store.id,
            companyId: store.companyId,
            name: store.name,
            storeCode: store.storeCode,
            location: store.location,
            phone: store.phone,
            isActive: false
        )
        
        _ = try await repository.save(deactivatedStore)
        
        if let index = stores.firstIndex(where: { $0.id == store.id }) {
            stores[index] = deactivatedStore
        }
    }
    
    func refresh() async {
        await loadData()
    }
}

