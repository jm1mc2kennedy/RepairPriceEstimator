import Foundation
import SwiftUI

/// ViewModel for managing users
@MainActor
final class UserManagementViewModel: ObservableObject {
    nonisolated(unsafe) private let repository: DataRepository
    private let authService: AuthService
    
    @Published var users: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var searchText: String = ""
    
    init(repository: DataRepository = CloudKitService.shared, authService: AuthService = AuthService.shared) {
        self.repository = repository
        self.authService = authService
    }
    
    func loadUsers() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let session = authService.currentSession else {
            errorMessage = "Not authenticated"
            showError = true
            return
        }
        
        do {
            let predicate = NSPredicate(format: "companyId == %@", session.company.id)
            let sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true)]
            var fetchedUsers = try await repository.query(User.self, predicate: predicate, sortDescriptors: sortDescriptors)
            
            // Filter by search text if provided
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                fetchedUsers = fetchedUsers.filter { user in
                    user.displayName.lowercased().contains(searchLower) ||
                    user.email.lowercased().contains(searchLower) ||
                    user.role.rawValue.lowercased().contains(searchLower)
                }
            }
            
            users = fetchedUsers
            print("✅ Loaded \(users.count) user(s)")
        } catch {
            print("❌ Error loading users: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func createUser(_ user: User) async throws -> User {
        guard let session = authService.currentSession else {
            throw UserManagementError.notAuthenticated
        }
        
        // Validate email uniqueness
        let emailPredicate = NSPredicate(format: "companyId == %@ AND email == %@", session.company.id, user.email)
        let existingUsers = try await repository.query(User.self, predicate: emailPredicate, sortDescriptors: nil)
        if !existingUsers.isEmpty {
            throw UserManagementError.emailAlreadyExists
        }
        
        let savedUser = try await repository.save(user)
        users.append(savedUser)
        users.sort { $0.displayName < $1.displayName }
        return savedUser
    }
    
    func updateUser(_ user: User) async throws -> User {
        let updatedUser = try await repository.save(user)
        
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = updatedUser
        }
        users.sort { $0.displayName < $1.displayName }
        
        return updatedUser
    }
    
    func deactivateUser(_ user: User) async throws {
        // Create a new User with isActive = false
        let deactivatedUser = User(
            id: user.id,
            companyId: user.companyId,
            storeIds: user.storeIds,
            role: user.role,
            displayName: user.displayName,
            email: user.email,
            isActive: false,
            createdAt: user.createdAt
        )
        
        _ = try await repository.save(deactivatedUser)
        
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = deactivatedUser
        }
    }
    
    func refresh() async {
        await loadUsers()
    }
}

enum UserManagementError: LocalizedError {
    case notAuthenticated
    case emailAlreadyExists
    case insufficientPermissions
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to manage users"
        case .emailAlreadyExists:
            return "A user with this email already exists"
        case .insufficientPermissions:
            return "You don't have permission to perform this action"
        }
    }
}

