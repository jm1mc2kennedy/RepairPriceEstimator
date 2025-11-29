import Foundation
import SwiftUI

/// ViewModel for managing guest CRUD operations
@MainActor
final class GuestListViewModel: ObservableObject {
    nonisolated(unsafe) private let repository: DataRepository
    private let authService: AuthService
    
    @Published var guests: [Guest] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var showError: Bool = false
    
    init(repository: DataRepository = CloudKitService.shared, authService: AuthService = AuthService.shared) {
        self.repository = repository
        self.authService = authService
    }
    
    /// Load guests from CloudKit
    func loadGuests() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let session = authService.currentSession else {
            errorMessage = "Not authenticated"
            showError = true
            return
        }
        
        do {
            var predicate: NSPredicate
            
            if !searchText.isEmpty {
                // Search by name, email, or phone
                // CloudKit doesn't support complex text search, so we'll load all and filter
                predicate = NSPredicate(format: "companyId == %@", session.company.id)
            } else {
                predicate = NSPredicate(format: "companyId == %@", session.company.id)
            }
            
            let sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true), NSSortDescriptor(key: "lastName", ascending: true)]
            var fetchedGuests = try await repository.query(Guest.self, predicate: predicate, sortDescriptors: sortDescriptors)
            
            // Filter by search text if provided (name, email, phone)
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                fetchedGuests = fetchedGuests.filter { guest in
                    guest.fullName.lowercased().contains(searchLower) ||
                    guest.email?.lowercased().contains(searchLower) == true ||
                    guest.phone?.contains(searchText) == true
                }
            }
            
            guests = fetchedGuests
            print("✅ Loaded \(guests.count) guest(s)")
        } catch {
            print("❌ Error loading guests: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    /// Create a new guest
    func createGuest(_ guest: Guest) async throws -> Guest {
        guard let session = authService.currentSession else {
            throw GuestError.notAuthenticated
        }
        
        // Validate guest data
        guard !guest.firstName.isEmpty && !guest.lastName.isEmpty else {
            throw GuestError.invalidData("First and last name are required")
        }
        
        do {
            let savedGuest = try await repository.save(guest)
            guests.append(savedGuest)
            print("✅ Created guest: \(savedGuest.fullName)")
            return savedGuest
        } catch {
            print("❌ Error creating guest: \(error)")
            throw GuestError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Update an existing guest
    func updateGuest(_ guest: Guest) async throws -> Guest {
        do {
            let updatedGuest = try await repository.save(guest)
            
            // Update in local array
            if let index = guests.firstIndex(where: { $0.id == guest.id }) {
                guests[index] = updatedGuest
            }
            
            print("✅ Updated guest: \(updatedGuest.fullName)")
            return updatedGuest
        } catch {
            print("❌ Error updating guest: \(error)")
            throw GuestError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Delete a guest (soft delete - set inactive flag if model supports it, otherwise hard delete)
    func deleteGuest(_ guest: Guest) async throws {
        do {
            try await repository.delete(Guest.self, id: guest.id)
            guests.removeAll { $0.id == guest.id }
            print("✅ Deleted guest: \(guest.fullName)")
        } catch {
            print("❌ Error deleting guest: \(error)")
            throw GuestError.deleteFailed(error.localizedDescription)
        }
    }
    
    /// Refresh guests (called by pull-to-refresh)
    func refresh() async {
        await loadGuests()
    }
    
    /// Get guest by ID
    func getGuest(id: String) async throws -> Guest? {
        return try await repository.fetch(Guest.self, id: id)
    }
}

// MARK: - Errors

enum GuestError: LocalizedError {
    case notAuthenticated
    case invalidData(String)
    case saveFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to manage guests"
        case .invalidData(let message):
            return message
        case .saveFailed(let message):
            return "Failed to save guest: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete guest: \(message)"
        }
    }
}

