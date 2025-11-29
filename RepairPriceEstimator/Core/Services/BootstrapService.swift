import Foundation

/// Service responsible for bootstrapping initial data and system setup
@MainActor
final class BootstrapService: ObservableObject {
    static let shared = BootstrapService()
    
    nonisolated(unsafe) private let repository: DataRepository
    @Published var isBootstrapped: Bool = false
    @Published var isBootstrapping: Bool = false
    
    init(repository: DataRepository = CloudKitService.shared) {
        self.repository = repository
    }
    
    /// Bootstrap initial data if needed
    func bootstrapInitialData() async throws {
        // Access CloudKitService directly to avoid protocol concurrency issues
        let cloudKitService = CloudKitService.shared
        guard await cloudKitService.isAvailable else {
            throw RepositoryError.notSignedInToiCloud
        }
        
        // Check if already bootstrapped
        if await isSystemBootstrapped() {
            // Verify ADMIN and SUPERADMIN users exist (required for hardcoded credentials)
            do {
                // Check for ADMIN user
                let adminPredicate = NSPredicate(format: "role == %@ AND isActive == 1", UserRole.admin.rawValue)
                let adminUsers = try await repository.query(User.self, predicate: adminPredicate, sortDescriptors: nil)
                
                // Check for SUPERADMIN user
                let superAdminPredicate = NSPredicate(format: "role == %@ AND isActive == 1", UserRole.superAdmin.rawValue)
                let superAdminUsers = try await repository.query(User.self, predicate: superAdminPredicate, sortDescriptors: nil)
                
                if adminUsers.isEmpty || superAdminUsers.isEmpty {
                    print("⚠️  Bootstrap detected but required admin users missing.")
                    print("   Found ADMIN: \(adminUsers.count), SUPERADMIN: \(superAdminUsers.count)")
                    print("   Creating missing admin users...")
                    try await createInitialUsers()
                } else {
                    print("ℹ️  Bootstrap already complete: Found ADMIN and SUPERADMIN users")
                }
            } catch {
                print("⚠️  Could not verify admin users, attempting to create: \(error)")
                try await createInitialUsers()
            }
            isBootstrapped = true
            return
        }
        
        isBootstrapping = true
        defer { isBootstrapping = false }
        
        print("🚀 Bootstrapping initial system data...")
        
        try await createInitialCompanyAndStore()
        try await createInitialUsers()
        try await createDefaultPricingRules()
        try await createDefaultServiceTypes()
        try await createDefaultMetalRates()
        try await createDefaultLaborRates()
        
        isBootstrapped = true
        print("✅ System bootstrap completed successfully")
    }
    
    // MARK: - Private Methods
    
    private func isSystemBootstrapped() async -> Bool {
        do {
            // Check if any companies exist by querying using a queryable field (name)
            let predicate = NSPredicate(format: "name != %@", "")
            let companies = try await repository.query(Company.self, predicate: predicate, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
            return !companies.isEmpty
        } catch {
            print("❌ Error checking bootstrap status: \(error)")
            return false
        }
    }
    
    private func createInitialCompanyAndStore() async throws {
        print("📋 Creating initial company and store...")
        
        // Create default company
        let company = Company(
            name: "Repair Price Estimator Demo",
            primaryContactInfo: "demo@jewelryrepair.com"
        )
        let savedCompany = try await repository.save(company)
        
        // Create default store
        let store = Store(
            companyId: savedCompany.id,
            name: "Main Store",
            storeCode: "001",
            location: "123 Main St, Anytown, USA",
            phone: "(555) 123-4567"
        )
        _ = try await repository.save(store)
        
        print("✅ Created company: \(savedCompany.name)")
        print("✅ Created store: \(store.name)")
    }
    
    private func createInitialUsers() async throws {
        print("👥 Creating initial users...")
        
        // Get the company ID
        let predicate = NSPredicate(format: "name != %@", "")
        let companies = try await repository.query(Company.self, predicate: predicate, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
        guard let company = companies.first else {
            throw BootstrapError.missingCompanyData
        }
        
        let storePredicate = NSPredicate(format: "companyId == %@", company.id)
        let stores = try await repository.query(Store.self, predicate: storePredicate, sortDescriptors: nil)
        guard let store = stores.first else {
            throw BootstrapError.missingStoreData
        }
        
        // Check if SUPERADMIN already exists
        let superAdminCheck = NSPredicate(format: "role == %@ AND isActive == 1", UserRole.superAdmin.rawValue)
        let existingSuperAdmins = try await repository.query(User.self, predicate: superAdminCheck, sortDescriptors: nil)
        
        if existingSuperAdmins.isEmpty {
            // Create SUPERADMIN user
            let superAdmin = User(
                companyId: company.id,
                storeIds: [store.id],
                role: .superAdmin,
                displayName: "Super Administrator",
                email: "superadmin@jewelryrepair.com",
                isActive: true
            )
            let savedSuperAdmin = try await repository.save(superAdmin)
            print("✅ Created SUPERADMIN user: \(savedSuperAdmin.email) (ID: \(savedSuperAdmin.id))")
        } else {
            print("ℹ️  SUPERADMIN user already exists: \(existingSuperAdmins.first?.email ?? "unknown")")
        }
        
        // Check if ADMIN already exists
        let adminCheck = NSPredicate(format: "role == %@ AND isActive == 1", UserRole.admin.rawValue)
        let existingAdmins = try await repository.query(User.self, predicate: adminCheck, sortDescriptors: nil)
        
        if existingAdmins.isEmpty {
            // Create ADMIN user
            let admin = User(
                companyId: company.id,
                storeIds: [store.id],
                role: .admin,
                displayName: "Administrator",
                email: "admin@jewelryrepair.com",
                isActive: true
            )
            let savedAdmin = try await repository.save(admin)
            print("✅ Created ADMIN user: \(savedAdmin.email) (ID: \(savedAdmin.id))")
        } else {
            print("ℹ️  ADMIN user already exists: \(existingAdmins.first?.email ?? "unknown")")
        }
        
        // Verify users were actually created by querying them back
        do {
            let verifyPredicate = NSPredicate(format: "role == %@ AND isActive == 1", UserRole.admin.rawValue)
            let verifyUsers = try await repository.query(User.self, predicate: verifyPredicate, sortDescriptors: nil)
            print("✅ Verification: Found \(verifyUsers.count) ADMIN user(s) in database")
            
            let superAdminPredicate = NSPredicate(format: "role == %@ AND isActive == 1", UserRole.superAdmin.rawValue)
            let verifySuperAdmins = try await repository.query(User.self, predicate: superAdminPredicate, sortDescriptors: nil)
            print("✅ Verification: Found \(verifySuperAdmins.count) SUPERADMIN user(s) in database")
        } catch {
            print("⚠️  Warning: Could not verify user creation: \(error)")
            print("   Error details: \(error)")
        }
    }
    
    private func createDefaultPricingRules() async throws {
        print("💰 Creating default pricing rules...")
        
        let predicate = NSPredicate(format: "name != %@", "")
        let companies = try await repository.query(Company.self, predicate: predicate, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
        guard let company = companies.first else {
            throw BootstrapError.missingCompanyData
        }
        
        // Create default pricing formula
        let formula = PricingFormula(
            metalMarkupPercentage: 2.0,    // 200% markup on metal
            laborMarkupPercentage: 1.5,    // 150% markup on labor
            fixedFee: 10.0,                // $10 fixed fee
            rushMultiplier: 1.5,           // 1.5x for rush jobs
            minimumCharge: 25.0            // $25 minimum
        )
        
        let pricingRule = PricingRule(
            companyId: company.id,
            name: "Standard Jewelry Repair Pricing",
            description: "Standard pricing formula for jewelry repair services",
            formulaDefinition: formula,
            allowManualOverride: true,
            requireManagerApprovalIfOverrideExceedsPercent: 10.0
        )
        
        _ = try await repository.save(pricingRule)
        print("✅ Created default pricing rule")
    }
    
    private func createDefaultServiceTypes() async throws {
        print("🔧 Creating default service types...")
        
        let predicate = NSPredicate(format: "name != %@", "")
        let companies = try await repository.query(Company.self, predicate: predicate, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
        guard let company = companies.first else {
            throw BootstrapError.missingCompanyData
        }
        
        let serviceTypes = [
            ServiceType(
                companyId: company.id,
                name: "Ring Sizing Up",
                category: .jewelryRepair,
                defaultSku: "RS-UP",
                defaultLaborMinutes: 30,
                defaultMetalUsageGrams: 0.5,
                baseRetail: 45.00,
                baseCost: 15.00
            ),
            ServiceType(
                companyId: company.id,
                name: "Ring Sizing Down",
                category: .jewelryRepair,
                defaultSku: "RS-DN",
                defaultLaborMinutes: 25,
                defaultMetalUsageGrams: 0.0,
                baseRetail: 35.00,
                baseCost: 12.00
            ),
            ServiceType(
                companyId: company.id,
                name: "Prong Retip (per prong)",
                category: .jewelryRepair,
                defaultSku: "PR-TIP",
                defaultLaborMinutes: 15,
                defaultMetalUsageGrams: 0.1,
                baseRetail: 25.00,
                baseCost: 8.00
            ),
            ServiceType(
                companyId: company.id,
                name: "Chain Repair",
                category: .jewelryRepair,
                defaultSku: "CH-REP",
                defaultLaborMinutes: 20,
                defaultMetalUsageGrams: 0.2,
                baseRetail: 35.00,
                baseCost: 12.00
            ),
            ServiceType(
                companyId: company.id,
                name: "Watch Battery Replacement",
                category: .watchService,
                defaultSku: "WB-REP",
                defaultLaborMinutes: 10,
                baseRetail: 15.00,
                baseCost: 5.00
            ),
            ServiceType(
                companyId: company.id,
                name: "Ultrasonic Cleaning",
                category: .cleaning,
                defaultSku: "UC-CLN",
                defaultLaborMinutes: 5,
                baseRetail: 10.00,
                baseCost: 2.00
            )
        ]
        
        for serviceType in serviceTypes {
            _ = try await repository.save(serviceType)
        }
        
        print("✅ Created \(serviceTypes.count) default service types")
    }
    
    private func createDefaultMetalRates() async throws {
        print("🥇 Creating default metal market rates...")
        
        let predicate = NSPredicate(format: "name != %@", "")
        let companies = try await repository.query(Company.self, predicate: predicate, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
        guard let company = companies.first else {
            throw BootstrapError.missingCompanyData
        }
        
        let metalRates = [
            MetalMarketRate(
                companyId: company.id,
                metalType: .gold14K,
                unit: .gramsPerGram,
                rate: 35.00
            ),
            MetalMarketRate(
                companyId: company.id,
                metalType: .gold18K,
                unit: .gramsPerGram,
                rate: 45.00
            ),
            MetalMarketRate(
                companyId: company.id,
                metalType: .platinum,
                unit: .gramsPerGram,
                rate: 28.00
            ),
            MetalMarketRate(
                companyId: company.id,
                metalType: .silver,
                unit: .gramsPerGram,
                rate: 0.85
            )
        ]
        
        for rate in metalRates {
            _ = try await repository.save(rate)
        }
        
        print("✅ Created \(metalRates.count) default metal market rates")
    }
    
    private func createDefaultLaborRates() async throws {
        print("⚒️ Creating default labor rates...")
        
        let predicate = NSPredicate(format: "name != %@", "")
        let companies = try await repository.query(Company.self, predicate: predicate, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
        guard let company = companies.first else {
            throw BootstrapError.missingCompanyData
        }
        
        let laborRates = [
            LaborRate(
                companyId: company.id,
                role: .benchJeweler,
                ratePerHour: 85.00
            ),
            LaborRate(
                companyId: company.id,
                role: .storeManager,
                ratePerHour: 65.00
            ),
            LaborRate(
                companyId: company.id,
                role: .associate,
                ratePerHour: 45.00
            )
        ]
        
        for rate in laborRates {
            _ = try await repository.save(rate)
        }
        
        print("✅ Created \(laborRates.count) default labor rates")
    }
}

// MARK: - Errors

enum BootstrapError: Error, LocalizedError {
    case missingCompanyData
    case missingStoreData
    case bootstrapFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingCompanyData:
            return "Company data not found during bootstrap"
        case .missingStoreData:
            return "Store data not found during bootstrap"
        case .bootstrapFailed(let error):
            return "Bootstrap failed: \(error.localizedDescription)"
        }
    }
}
