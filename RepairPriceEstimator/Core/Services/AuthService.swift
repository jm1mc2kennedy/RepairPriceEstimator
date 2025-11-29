import Foundation

/// Credentials for authentication
struct AuthCredentials: Sendable {
    let username: String
    let password: String
}

/// Current user session information
struct UserSession: Sendable {
    let user: User
    let company: Company
    let primaryStore: Store
    let accessibleStores: [Store]
    
    /// Whether the user can access admin features
    var canAccessAdmin: Bool {
        user.role.canAccessAdmin
    }
    
    /// Whether the user can approve pricing overrides
    var canApproveOverrides: Bool {
        user.role.canApproveOverrides
    }
}

/// Service for authentication and session management
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    private let repository: DataRepository
    
    @Published var isAuthenticated: Bool = false
    @Published var currentSession: UserSession?
    @Published var isLoading: Bool = false
    
    // Hardcoded credentials for MVP (will be replaced with proper auth)
    private let defaultCredentials = [
        "SUPERadmin": "SUPERadmin",
        "admin": "admin"
    ]
    
    init(repository: DataRepository = CloudKitService.shared) {
        self.repository = repository
    }
    
    /// Authenticate user with username and password
    func authenticate(credentials: AuthCredentials) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Validate credentials against hardcoded values
        guard let expectedPassword = defaultCredentials[credentials.username],
              expectedPassword == credentials.password else {
            throw AuthError.invalidCredentials
        }
        
        // Map username to role
        let role: UserRole
        switch credentials.username {
        case "SUPERadmin":
            role = .superAdmin
        case "admin":
            role = .admin
        default:
            throw AuthError.invalidCredentials
        }
        
        // Find the user in the database
        let predicate = NSPredicate(format: "role == %@ AND isActive == YES", role.rawValue)
        let users = try await repository.query(User.self, predicate: predicate, sortDescriptors: nil)
        
        guard let user = users.first else {
            throw AuthError.userNotFound
        }
        
        // Load user session data
        let session = try await createUserSession(for: user)
        
        // Store credentials for future use (in UserDefaults for MVP)
        storeCredentials(credentials)
        
        currentSession = session
        isAuthenticated = true
        
        print("✅ User authenticated: \(user.displayName) (\(user.role.rawValue))")
    }
    
    /// Sign out the current user
    func signOut() {
        currentSession = nil
        isAuthenticated = false
        clearStoredCredentials()
        print("👋 User signed out")
    }
    
    /// Attempt to restore previous session on app launch
    func attemptAutoLogin() async {
        guard let storedCredentials = getStoredCredentials() else {
            print("ℹ️ No stored credentials found")
            return
        }
        
        do {
            try await authenticate(credentials: storedCredentials)
            print("✅ Auto-login successful")
        } catch {
            print("❌ Auto-login failed: \(error)")
            clearStoredCredentials()
        }
    }
    
    /// Check if current user has permission for specific action
    func hasPermission(for action: PermissionAction) -> Bool {
        guard let session = currentSession else { return false }
        
        switch action {
        case .viewQuotes:
            return true // All authenticated users can view quotes
        case .createQuotes:
            return true // All authenticated users can create quotes
        case .editQuotes:
            return session.user.role != .associate // Associates can't edit quotes after creation
        case .deleteQuotes:
            return session.canApproveOverrides // Only managers and above
        case .accessAdmin:
            return session.canAccessAdmin
        case .manageUsers:
            return session.user.role == .superAdmin // Only super admin
        case .managePricing:
            return session.canAccessAdmin
        case .approveOverrides:
            return session.canApproveOverrides
        case .viewAllStores:
            return session.user.role == .superAdmin || session.user.role == .admin
        }
    }
    
    // MARK: - Private Methods
    
    private func createUserSession(for user: User) async throws -> UserSession {
        // Load company
        guard let company = try await repository.fetch(Company.self, id: user.companyId) else {
            throw AuthError.companyNotFound
        }
        
        // Load accessible stores
        var accessibleStores: [Store] = []
        for storeId in user.storeIds {
            if let store = try await repository.fetch(Store.self, id: storeId) {
                accessibleStores.append(store)
            }
        }
        
        guard let primaryStore = accessibleStores.first else {
            throw AuthError.noAccessibleStores
        }
        
        return UserSession(
            user: user,
            company: company,
            primaryStore: primaryStore,
            accessibleStores: accessibleStores
        )
    }
    
    private func storeCredentials(_ credentials: AuthCredentials) {
        UserDefaults.standard.set(credentials.username, forKey: "stored_username")
        UserDefaults.standard.set(credentials.password, forKey: "stored_password")
    }
    
    private func getStoredCredentials() -> AuthCredentials? {
        guard let username = UserDefaults.standard.string(forKey: "stored_username"),
              let password = UserDefaults.standard.string(forKey: "stored_password") else {
            return nil
        }
        return AuthCredentials(username: username, password: password)
    }
    
    private func clearStoredCredentials() {
        UserDefaults.standard.removeObject(forKey: "stored_username")
        UserDefaults.standard.removeObject(forKey: "stored_password")
    }
}

// MARK: - Permission Actions

enum PermissionAction {
    case viewQuotes
    case createQuotes
    case editQuotes
    case deleteQuotes
    case accessAdmin
    case manageUsers
    case managePricing
    case approveOverrides
    case viewAllStores
}

// MARK: - Errors

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case userNotFound
    case companyNotFound
    case noAccessibleStores
    case sessionExpired
    case insufficientPermissions
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password"
        case .userNotFound:
            return "User account not found"
        case .companyNotFound:
            return "Company information not found"
        case .noAccessibleStores:
            return "No accessible stores found for user"
        case .sessionExpired:
            return "Session has expired. Please log in again"
        case .insufficientPermissions:
            return "Insufficient permissions for this action"
        }
    }
}
