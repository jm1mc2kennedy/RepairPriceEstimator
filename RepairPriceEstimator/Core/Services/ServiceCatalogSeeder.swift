import Foundation

/// Service for populating the service catalog with Springer's exact SKUs and pricing
@MainActor
final class ServiceCatalogSeeder {
    nonisolated(unsafe) private let repository: DataRepository
    
    init(repository: DataRepository = CloudKitService.shared) {
        self.repository = repository
    }
    
    /// Seed all Springer's service types with exact SKUs and pricing
    func seedServiceCatalog(companyId: String) async throws {
        print("🌱 Seeding service catalog for company: \(companyId)")
        
        // Ring sizing services (27 SKUs)
        try await seedRingSizingServices(companyId: companyId)
        
        // Purchase setting services (20 SKUs)  
        try await seedPurchaseSettingServices(companyId: companyId)
        
        // Watch services
        try await seedWatchServices(companyId: companyId)
        
        // Generic jewelry services
        try await seedGenericJewelryServices(companyId: companyId)
        
        print("✅ Service catalog seeding completed")
    }
    
    // MARK: - Ring Sizing Services
    
    private func seedRingSizingServices(companyId: String) async throws {
        print("💍 Seeding ring sizing services...")
        
        // 14K Purchase Sizing
        let gold14KServices = [
            // Size Down
            ServiceType(
                companyId: companyId,
                name: "14K Purchase Sizing under 3mm - Size Down",
                category: .jewelryRepair,
                defaultSku: "PUR143001",
                defaultLaborMinutes: 30,
                defaultMetalUsageGrams: 0,
                baseRetail: 180,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold14K],
                sizingCategory: .under3mm
            ),
            ServiceType(
                companyId: companyId,
                name: "14K Purchase Sizing 3-5mm - Size Down",
                category: .jewelryRepair,
                defaultSku: "PUR145001",
                defaultLaborMinutes: 30,
                defaultMetalUsageGrams: 0,
                baseRetail: 192,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold14K],
                sizingCategory: .mm3to5
            ),
            ServiceType(
                companyId: companyId,
                name: "14K Purchase Sizing 5-8mm - Size Down",
                category: .jewelryRepair,
                defaultSku: "PUR148001",
                defaultLaborMinutes: 35,
                defaultMetalUsageGrams: 0,
                baseRetail: 210,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold14K],
                sizingCategory: .mm5to8
            ),
            
            // First Size Up
            ServiceType(
                companyId: companyId,
                name: "14K Purchase Sizing under 3mm - First Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR143002",
                defaultLaborMinutes: 45,
                defaultMetalUsageGrams: 0.5,
                baseRetail: 222,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold14K],
                sizingCategory: .under3mm
            ),
            ServiceType(
                companyId: companyId,
                name: "14K Purchase Sizing 3-5mm - First Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR145002",
                defaultLaborMinutes: 50,
                defaultMetalUsageGrams: 0.7,
                baseRetail: 276,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold14K],
                sizingCategory: .mm3to5
            ),
            ServiceType(
                companyId: companyId,
                name: "14K Purchase Sizing 5-8mm - First Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR148002",
                defaultLaborMinutes: 55,
                defaultMetalUsageGrams: 0.8,
                baseRetail: 282,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold14K],
                sizingCategory: .mm5to8
            ),
            
            // Each Additional Size Up
            ServiceType(
                companyId: companyId,
                name: "14K Purchase Sizing under 3mm - Each Additional Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR143003",
                defaultLaborMinutes: 20,
                defaultMetalUsageGrams: 0.2,
                baseRetail: 54,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold14K],
                sizingCategory: .under3mm
            ),
            ServiceType(
                companyId: companyId,
                name: "14K Purchase Sizing 3-5mm - Each Additional Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR145003",
                defaultLaborMinutes: 25,
                defaultMetalUsageGrams: 0.3,
                baseRetail: 78,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold14K],
                sizingCategory: .mm3to5
            ),
            ServiceType(
                companyId: companyId,
                name: "14K Purchase Sizing 5-8mm - Each Additional Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR148003",
                defaultLaborMinutes: 30,
                defaultMetalUsageGrams: 0.4,
                baseRetail: 90,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold14K],
                sizingCategory: .mm5to8
            )
        ]
        
        for service in gold14KServices {
            _ = try await repository.save(service)
        }
        
        // 16K Purchase Sizing (similar pattern with different SKUs and prices)
        let gold16KServices = [
            // Size Down
            ServiceType(
                companyId: companyId,
                name: "16K Purchase Sizing under 3mm - Size Down",
                category: .jewelryRepair,
                defaultSku: "PUR183001",
                defaultLaborMinutes: 30,
                baseRetail: 195,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold18K], // Using 18K as closest to 16K
                sizingCategory: .under3mm
            ),
            ServiceType(
                companyId: companyId,
                name: "16K Purchase Sizing 3-5mm - Size Down",
                category: .jewelryRepair,
                defaultSku: "PUR185001",
                defaultLaborMinutes: 30,
                baseRetail: 220,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold18K],
                sizingCategory: .mm3to5,
            ),
            ServiceType(
                companyId: companyId,
                name: "16K Purchase Sizing 5-8mm - Size Down",
                category: .jewelryRepair,
                defaultSku: "PUR188001",
                defaultLaborMinutes: 35,
                baseRetail: 245,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold18K],
                sizingCategory: .mm5to8,
            ),
            
            // First Size Up
            ServiceType(
                companyId: companyId,
                name: "16K Purchase Sizing under 3mm - First Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR183002",
                defaultLaborMinutes: 45,
                defaultMetalUsageGrams: 0.5,
                baseRetail: 270,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold18K],
                sizingCategory: .under3mm,
            ),
            ServiceType(
                companyId: companyId,
                name: "16K Purchase Sizing 3-5mm - First Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR185002",
                defaultLaborMinutes: 50,
                defaultMetalUsageGrams: 0.7,
                baseRetail: 300,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold18K],
                sizingCategory: .mm3to5,
            ),
            ServiceType(
                companyId: companyId,
                name: "16K Purchase Sizing 5-8mm - First Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR188002",
                defaultLaborMinutes: 55,
                defaultMetalUsageGrams: 0.8,
                baseRetail: 320,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold18K],
                sizingCategory: .mm5to8,
            ),
            
            // Each Additional Size Up
            ServiceType(
                companyId: companyId,
                name: "16K Purchase Sizing under 3mm - Each Additional Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR183003",
                defaultLaborMinutes: 20,
                defaultMetalUsageGrams: 0.2,
                baseRetail: 65,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold18K],
                sizingCategory: .under3mm,
            ),
            ServiceType(
                companyId: companyId,
                name: "16K Purchase Sizing 3-5mm - Each Additional Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR185003",
                defaultLaborMinutes: 25,
                defaultMetalUsageGrams: 0.3,
                baseRetail: 95,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold18K],
                sizingCategory: .mm3to5,
            ),
            ServiceType(
                companyId: companyId,
                name: "16K Purchase Sizing 5-8mm - Each Additional Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR188003",
                defaultLaborMinutes: 30,
                defaultMetalUsageGrams: 0.4,
                baseRetail: 120,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.gold18K],
                sizingCategory: .mm5to8,
            )
        ]
        
        for service in gold16KServices {
            _ = try await repository.save(service)
        }
        
        // Platinum Purchase Sizing
        let platinumServices = [
            // Size Down
            ServiceType(
                companyId: companyId,
                name: "Platinum Purchase Sizing under 3mm - Size Down",
                category: .jewelryRepair,
                defaultSku: "PUR953001",
                defaultLaborMinutes: 35,
                baseRetail: 190,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.platinum],
                sizingCategory: .under3mm,
            ),
            ServiceType(
                companyId: companyId,
                name: "Platinum Purchase Sizing 3-5mm - Size Down",
                category: .jewelryRepair,
                defaultSku: "PUR955001",
                defaultLaborMinutes: 35,
                baseRetail: 200,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.platinum],
                sizingCategory: .mm3to5,
            ),
            ServiceType(
                companyId: companyId,
                name: "Platinum Purchase Sizing 5-8mm - Size Down",
                category: .jewelryRepair,
                defaultSku: "PUR958001",
                defaultLaborMinutes: 40,
                baseRetail: 225,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.platinum],
                sizingCategory: .mm5to8,
            ),
            
            // First Size Up
            ServiceType(
                companyId: companyId,
                name: "Platinum Purchase Sizing under 3mm - First Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR953002",
                defaultLaborMinutes: 50,
                defaultMetalUsageGrams: 0.6,
                baseRetail: 255,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.platinum],
                sizingCategory: .under3mm,
            ),
            ServiceType(
                companyId: companyId,
                name: "Platinum Purchase Sizing 3-5mm - First Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR955002",
                defaultLaborMinutes: 55,
                defaultMetalUsageGrams: 0.8,
                baseRetail: 350,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.platinum],
                sizingCategory: .mm3to5,
            ),
            ServiceType(
                companyId: companyId,
                name: "Platinum Purchase Sizing 5-8mm - First Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR958002",
                defaultLaborMinutes: 60,
                defaultMetalUsageGrams: 1.0,
                baseRetail: 435,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.platinum],
                sizingCategory: .mm5to8,
            ),
            
            // Each Additional Size Up
            ServiceType(
                companyId: companyId,
                name: "Platinum Purchase Sizing under 3mm - Each Additional Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR953003",
                defaultLaborMinutes: 25,
                defaultMetalUsageGrams: 0.3,
                baseRetail: 80,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.platinum],
                sizingCategory: .under3mm,
            ),
            ServiceType(
                companyId: companyId,
                name: "Platinum Purchase Sizing 3-5mm - Each Additional Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR955003",
                defaultLaborMinutes: 30,
                defaultMetalUsageGrams: 0.4,
                baseRetail: 130,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.platinum],
                sizingCategory: .mm3to5,
            ),
            ServiceType(
                companyId: companyId,
                name: "Platinum Purchase Sizing 5-8mm - Each Additional Size Up",
                category: .jewelryRepair,
                defaultSku: "PUR958003",
                defaultLaborMinutes: 35,
                defaultMetalUsageGrams: 0.5,
                baseRetail: 176,
                baseCost: 140,
                requiresSpringersCheck: true,
                metalTypes: [.platinum],
                sizingCategory: .mm5to8
            )
        ]
        
        for service in platinumServices {
            _ = try await repository.save(service)
        }
        
        print("✅ Ring sizing services seeded (27 services)")
    }
    
    // MARK: - Purchase Setting Services
    
    private func seedPurchaseSettingServices(companyId: String) async throws {
        print("💎 Seeding purchase setting services...")
        
        let settingServices = [
            // Round Prong Settings
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Round Prong up to 6mm",
                category: .jewelryRepair,
                defaultSku: "PRSTRP6001",
                defaultLaborMinutes: 60,
                baseRetail: 95,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Round Prong up to 9mm",
                category: .jewelryRepair,
                defaultSku: "PRSTRP9001",
                defaultLaborMinutes: 90,
                baseRetail: 175,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Round Prong up to 11mm",
                category: .jewelryRepair,
                defaultSku: "PRSTRP1101",
                defaultLaborMinutes: 120,
                baseRetail: 230,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Round Prong up to 13mm",
                category: .jewelryRepair,
                defaultSku: "PRSTRP1301",
                defaultLaborMinutes: 150,
                baseRetail: 305,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            
            // Round Bezel Settings
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Round Bezel up to 6mm",
                category: .jewelryRepair,
                defaultSku: "PRSTRB6002",
                defaultLaborMinutes: 75,
                baseRetail: 115,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Round Bezel up to 9mm",
                category: .jewelryRepair,
                defaultSku: "PRSTRB9002",
                defaultLaborMinutes: 105,
                baseRetail: 195,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Round Bezel up to 11mm",
                category: .jewelryRepair,
                defaultSku: "PRSTRB1102",
                defaultLaborMinutes: 135,
                baseRetail: 295,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Round Bezel up to 13mm",
                category: .jewelryRepair,
                defaultSku: "PRSTRB1302",
                defaultLaborMinutes: 165,
                baseRetail: 360,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            
            // Fancy Prong Settings
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Fancy Prong up to 6mm",
                category: .jewelryRepair,
                defaultSku: "PRSTPP6003",
                defaultLaborMinutes: 45,
                baseRetail: 60,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Fancy Prong up to 9mm",
                category: .jewelryRepair,
                defaultSku: "PRSTPP9003",
                defaultLaborMinutes: 75,
                baseRetail: 110,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Fancy Prong up to 11mm",
                category: .jewelryRepair,
                defaultSku: "PRSTPP1103",
                defaultLaborMinutes: 105,
                baseRetail: 185,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Fancy Prong up to 13mm",
                category: .jewelryRepair,
                defaultSku: "PRSTPP1303",
                defaultLaborMinutes: 135,
                baseRetail: 220,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            
            // Fancy Bezel Settings
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Fancy Bezel up to 6mm",
                category: .jewelryRepair,
                defaultSku: "PRSTPB6004",
                defaultLaborMinutes: 30,
                baseRetail: 40,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Fancy Bezel up to 9mm",
                category: .jewelryRepair,
                defaultSku: "PRSTPB9004",
                defaultLaborMinutes: 75,
                baseRetail: 110,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Fancy Bezel up to 11mm",
                category: .jewelryRepair,
                defaultSku: "PRSTPB1104",
                defaultLaborMinutes: 105,
                baseRetail: 165,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Fancy Bezel up to 13mm",
                category: .jewelryRepair,
                defaultSku: "PRSTPB1304",
                defaultLaborMinutes: 120,
                baseRetail: 200,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            
            // Princess Cut Settings
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Princess Cut up to 6mm",
                category: .jewelryRepair,
                defaultSku: "PRSTPB6005",
                defaultLaborMinutes: 45,
                baseRetail: 52,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Princess Cut up to 9mm",
                category: .jewelryRepair,
                defaultSku: "PRSTPB9005",
                defaultLaborMinutes: 75,
                baseRetail: 110,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Princess Cut up to 11mm",
                category: .jewelryRepair,
                defaultSku: "PRSTPB1105",
                defaultLaborMinutes: 105,
                baseRetail: 185,
                baseCost: 140,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Set Princess Cut up to 13mm",
                category: .jewelryRepair,
                defaultSku: "PRSTPB1305",
                defaultLaborMinutes: 120,
                baseRetail: 185,
                baseCost: 140,
                requiresSpringersCheck: true
            )
        ]
        
        for service in settingServices {
            _ = try await repository.save(service)
        }
        
        print("✅ Purchase setting services seeded (20 services)")
    }
    
    // MARK: - Watch Services
    
    private func seedWatchServices(companyId: String) async throws {
        print("⌚ Seeding watch services...")
        
        let watchServices = [
            ServiceType(
                companyId: companyId,
                name: "Generic Watch Repair",
                category: .watchService,
                defaultSku: "14WR0001",
                defaultLaborMinutes: 60,
                baseRetail: 0, // Generic pricing
                baseCost: 0,
                isGenericSku: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Generic Watch Service",
                category: .watchService,
                defaultSku: "14WS0001",
                defaultLaborMinutes: 30,
                baseRetail: 0,
                baseCost: 0,
                isGenericSku: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Watch Parts/Findings",
                category: .watchService,
                defaultSku: "14WST0001",
                defaultLaborMinutes: 15,
                baseRetail: 0,
                baseCost: 0,
                isGenericSku: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Battery & Pressure Test",
                category: .watchService,
                defaultSku: "14BPT0001",
                defaultLaborMinutes: 15,
                baseRetail: 25,
                baseCost: 8
            ),
            ServiceType(
                companyId: companyId,
                name: "Watch Bracelet Sizing",
                category: .watchService,
                defaultSku: "14WTSZ20",
                defaultLaborMinutes: 20,
                baseRetail: 20,
                baseCost: 5,
                requiresSpringersCheck: true // Free for Springer's purchases
            )
        ]
        
        for service in watchServices {
            _ = try await repository.save(service)
        }
        
        print("✅ Watch services seeded (5 services)")
    }
    
    // MARK: - Generic Jewelry Services
    
    private func seedGenericJewelryServices(companyId: String) async throws {
        print("💎 Seeding generic jewelry services...")
        
        let jewelryServices = [
            ServiceType(
                companyId: companyId,
                name: "Generic Jewelry Repair",
                category: .jewelryRepair,
                defaultSku: "14JR0001",
                defaultLaborMinutes: 45,
                baseRetail: 0,
                baseCost: 0,
                isGenericSku: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Generic Service",
                category: .jewelryRepair,
                defaultSku: "14JS0001",
                defaultLaborMinutes: 30,
                baseRetail: 0,
                baseCost: 0,
                isGenericSku: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Generic Finding",
                category: .jewelryRepair,
                defaultSku: "14JSF0001",
                defaultLaborMinutes: 20,
                baseRetail: 0,
                baseCost: 0,
                isGenericSku: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Purchase Sizing (Generic)",
                category: .jewelryRepair,
                defaultSku: "PURCHSIZE",
                defaultLaborMinutes: 45,
                baseRetail: 0,
                baseCost: 0,
                isGenericSku: true,
                requiresSpringersCheck: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Engraving",
                category: .engraving,
                defaultSku: "14JSE0001",
                defaultLaborMinutes: 30,
                baseRetail: 0,
                baseCost: 0,
                isGenericSku: true
            ),
            ServiceType(
                companyId: companyId,
                name: "Return No Work",
                category: .other,
                defaultSku: "RNW",
                defaultLaborMinutes: 0,
                baseRetail: 0,
                baseCost: 0
            )
        ]
        
        for service in jewelryServices {
            _ = try await repository.save(service)
        }
        
        print("✅ Generic jewelry services seeded (6 services)")
    }
}
