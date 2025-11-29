import Foundation

/// Credentials for authentication
struct AuthCredentials: Sendable {
    let username: String
    let password: String
}

/// Data for user registration
struct SignUpData: Sendable {
    let username: String
    let password: String
    let displayName: String
    let email: String
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
    
    nonisolated(unsafe) private let repository: DataRepository
    
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
        // CloudKit stores booleans as INT64 (1 = true, 0 = false)
        let predicate = NSPredicate(format: "role == %@ AND isActive == 1", role.rawValue)
        
        print("🔍 Searching for user with role: \(role.rawValue)")
        let users: [User]
        do {
            users = try await repository.query(User.self, predicate: predicate, sortDescriptors: nil)
            print("📊 Found \(users.count) user(s) with role \(role.rawValue)")
        } catch let error as RepositoryError {
            print("❌ Repository error during authentication: \(error)")
            if case .notSignedInToiCloud = error {
                throw error
            }
            print("⚠️  This may indicate CloudKit schema hasn't been set up.")
            print("   See CLOUDKIT_SCHEMA_SETUP.md for setup instructions.")
            throw AuthError.userNotFound
        } catch {
            print("❌ Error querying users: \(error)")
            print("⚠️  This may indicate CloudKit schema hasn't been set up.")
            print("   See CLOUDKIT_SCHEMA_SETUP.md for setup instructions.")
            throw AuthError.userNotFound
        }
        
        guard let user = users.first else {
            print("⚠️  No users found with role: \(role.rawValue)")
            
            // Try to query all users to see what exists
            do {
                // Use email field which is always present and queryable
                let allUsers = try await repository.query(User.self, predicate: NSPredicate(format: "email != %@", ""), sortDescriptors: nil)
                print("📋 Total users in database: \(allUsers.count)")
                for u in allUsers {
                    print("   - User: \(u.email), Role: \(u.role.rawValue), Active: \(u.isActive)")
                }
            } catch {
                print("   Could not query all users: \(error)")
            }
            
            print("   This likely means bootstrap hasn't run successfully.")
            print("   Ensure CloudKit schema is set up and bootstrap completed.")
            print("   See CLOUDKIT_SCHEMA_SETUP.md for setup instructions.")
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
    
    /// Sign up a new user
    func signUp(data: SignUpData) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Check if email is already taken
        let predicate = NSPredicate(format: "email == %@", data.email)
        let existingUsers = try await repository.query(User.self, predicate: predicate, sortDescriptors: nil)
        if !existingUsers.isEmpty {
            throw AuthError.emailAlreadyExists
        }
        
        // Get or create company and store
        let (company, store) = try await getOrCreateCompanyAndStore()
        
        // Create new user with ASSOCIATE role by default
        let newUser = User(
            companyId: company.id,
            storeIds: [store.id],
            role: .associate,
            displayName: data.displayName,
            email: data.email,
            isActive: true
        )
        
        let savedUser = try await repository.save(newUser)
        
        // Store credentials for auto-login
        let credentials = AuthCredentials(username: data.username, password: data.password)
        storeCredentials(credentials)
        
        // Authenticate the newly created user
        try await authenticate(credentials: credentials)
        
        print("✅ User signed up successfully: \(savedUser.displayName)")
    }
    
    /// Get existing company and store, or create default ones if they don't exist
    private func getOrCreateCompanyAndStore() async throws -> (Company, Store) {
        // Try to get existing company
        let predicate = NSPredicate(format: "name != %@", "")
        let sortDesc = [NSSortDescriptor(key: "name", ascending: true)]
        let companies = try await repository.query(Company.self, predicate: predicate, sortDescriptors: sortDesc)
        
        if let company = companies.first {
            // Get existing store for this company
            let storePredicate = NSPredicate(format: "companyId == %@", company.id)
            let stores = try await repository.query(Store.self, predicate: storePredicate, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
            
            if let store = stores.first {
                return (company, store)
            } else {
                // Create default store
                let store = Store(
                    companyId: company.id,
                    name: "Main Store",
                    storeCode: "001",
                    location: "123 Main St, Anytown, USA",
                    phone: "(555) 123-4567"
                )
                let savedStore = try await repository.save(store)
                return (company, savedStore)
            }
        } else {
            // Create default company and store
            let company = Company(
                name: "Repair Price Estimator",
                primaryContactInfo: "info@jewelryrepair.com"
            )
            let savedCompany = try await repository.save(company)
            
            let store = Store(
                companyId: savedCompany.id,
                name: "Main Store",
                storeCode: "001",
                location: "123 Main St, Anytown, USA",
                phone: "(555) 123-4567"
            )
            let savedStore = try await repository.save(store)
            
            return (savedCompany, savedStore)
        }
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
    
    /// Refresh the current session after user data has been updated
    func refreshSession() async {
        guard let user = currentSession?.user else { return }
        do {
            if let updatedUser = try await repository.fetch(User.self, id: user.id) {
                let session = try await createUserSession(for: updatedUser)
                currentSession = session
            }
        } catch {
            print("❌ Error refreshing session: \(error)")
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
    case emailAlreadyExists
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password. Please check your credentials and try again."
        case .userNotFound:
            return "User account not found. The system may not be initialized yet. " +
                   "Ensure CloudKit schema is set up and bootstrap has run successfully. " +
                   "See CLOUDKIT_SCHEMA_SETUP.md for setup instructions."
        case .companyNotFound:
            return "Company information not found. The system may not be initialized yet."
        case .noAccessibleStores:
            return "No accessible stores found for user. Please contact your administrator."
        case .sessionExpired:
            return "Session has expired. Please log in again."
        case .insufficientPermissions:
            return "Insufficient permissions for this action."
        case .emailAlreadyExists:
            return "An account with this email already exists. " +
                   "Please use a different email or sign in instead."
        }
    }
}
