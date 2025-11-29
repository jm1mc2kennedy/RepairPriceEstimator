import Foundation
import SwiftUI

/// ViewModel for managing service type CRUD operations
@MainActor
final class ServiceTypeListViewModel: ObservableObject {
    nonisolated(unsafe) private let repository: DataRepository
    private let authService: AuthService
    
    @Published var serviceTypes: [ServiceType] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedCategory: ServiceCategory? = nil
    @Published var showError: Bool = false
    
    init(repository: DataRepository = CloudKitService.shared, authService: AuthService = AuthService.shared) {
        self.repository = repository
        self.authService = authService
    }
    
    /// Load service types from CloudKit
    func loadServiceTypes() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let session = authService.currentSession else {
            errorMessage = "Not authenticated"
            showError = true
            return
        }
        
        do {
            var predicates: [NSPredicate] = []
            predicates.append(NSPredicate(format: "companyId == %@", session.company.id))
            predicates.append(NSPredicate(format: "isActive == 1"))
            
            // Category filter
            if let category = selectedCategory {
                predicates.append(NSPredicate(format: "category == %@", category.rawValue))
            }
            
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            var fetchedServiceTypes = try await repository.query(ServiceType.self, predicate: predicate, sortDescriptors: sortDescriptors)
            
            // Filter by search text if provided (name or SKU)
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                fetchedServiceTypes = fetchedServiceTypes.filter { serviceType in
                    serviceType.name.lowercased().contains(searchLower) ||
                    serviceType.defaultSku.lowercased().contains(searchLower)
                }
            }
            
            serviceTypes = fetchedServiceTypes
            print("✅ Loaded \(serviceTypes.count) service type(s)")
        } catch {
            print("❌ Error loading service types: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    /// Create a new service type
    func createServiceType(_ serviceType: ServiceType) async throws -> ServiceType {
        guard let session = authService.currentSession else {
            throw ServiceTypeError.notAuthenticated
        }
        
        // Validate SKU uniqueness
        try await validateSKUUniqueness(serviceType.defaultSku, excludingId: nil, companyId: session.company.id)
        
        do {
            let savedServiceType = try await repository.save(serviceType)
            serviceTypes.append(savedServiceType)
            serviceTypes.sort { $0.name < $1.name }
            print("✅ Created service type: \(savedServiceType.name)")
            return savedServiceType
        } catch {
            print("❌ Error creating service type: \(error)")
            throw ServiceTypeError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Update an existing service type
    func updateServiceType(_ serviceType: ServiceType) async throws -> ServiceType {
        // Validate SKU uniqueness (excluding current service type)
        try await validateSKUUniqueness(serviceType.defaultSku, excludingId: serviceType.id, companyId: serviceType.companyId)
        
        do {
            let updatedServiceType = try await repository.save(serviceType)
            
            // Update in local array
            if let index = serviceTypes.firstIndex(where: { $0.id == serviceType.id }) {
                serviceTypes[index] = updatedServiceType
            }
            serviceTypes.sort { $0.name < $1.name }
            
            print("✅ Updated service type: \(updatedServiceType.name)")
            return updatedServiceType
        } catch {
            print("❌ Error updating service type: \(error)")
            throw ServiceTypeError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Delete (deactivate) a service type
    func deleteServiceType(_ serviceType: ServiceType) async throws {
        // Soft delete by setting isActive to false
        var updatedServiceType = serviceType
        // Note: ServiceType is a struct, so we can't mutate isActive directly
        // We need to create a new instance with isActive = false
        let deactivatedServiceType = ServiceType(
            id: serviceType.id,
            companyId: serviceType.companyId,
            name: serviceType.name,
            category: serviceType.category,
            defaultSku: serviceType.defaultSku,
            defaultLaborMinutes: serviceType.defaultLaborMinutes,
            defaultMetalUsageGrams: serviceType.defaultMetalUsageGrams,
            baseRetail: serviceType.baseRetail,
            baseCost: serviceType.baseCost,
            pricingFormulaId: serviceType.pricingFormulaId,
            isActive: false,
            isGenericSku: serviceType.isGenericSku,
            requiresSpringersCheck: serviceType.requiresSpringersCheck,
            metalTypes: serviceType.metalTypes,
            sizingCategory: serviceType.sizingCategory,
            watchBrand: serviceType.watchBrand,
            estimateRequired: serviceType.estimateRequired,
            vendorService: serviceType.vendorService,
            qualityControlRequired: serviceType.qualityControlRequired
        )
        
        do {
            _ = try await repository.save(deactivatedServiceType)
            
            // Update in local array
            if let index = serviceTypes.firstIndex(where: { $0.id == serviceType.id }) {
                serviceTypes[index] = deactivatedServiceType
            }
            
            print("✅ Deactivated service type: \(serviceType.name)")
        } catch {
            print("❌ Error deactivating service type: \(error)")
            throw ServiceTypeError.deleteFailed(error.localizedDescription)
        }
    }
    
    /// Validate SKU uniqueness within company
    private func validateSKUUniqueness(_ sku: String, excludingId: String?, companyId: String) async throws {
        let predicate = NSPredicate(format: "companyId == %@ AND defaultSku == %@", companyId, sku)
        let existingServiceTypes = try await repository.query(ServiceType.self, predicate: predicate, sortDescriptors: nil)
        
        // Check if SKU is taken by another service type
        if let existing = existingServiceTypes.first(where: { $0.id != excludingId }) {
            throw ServiceTypeError.duplicateSKU(existing.name)
        }
    }
    
    /// Refresh service types (called by pull-to-refresh)
    func refresh() async {
        await loadServiceTypes()
    }
}

// MARK: - Errors

enum ServiceTypeError: LocalizedError {
    case notAuthenticated
    case duplicateSKU(String)
    case saveFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to manage service types"
        case .duplicateSKU(let existingName):
            return "SKU already exists for service type: \(existingName)"
        case .saveFailed(let message):
            return "Failed to save service type: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete service type: \(message)"
        }
    }
}

