import XCTest
@testable import RepairPriceEstimator

/// Test suite for PricingEngine calculations
@MainActor
final class PricingEngineTests: XCTestCase {
    
    private var pricingEngine: PricingEngine!
    private var mockRepository: MockDataRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockDataRepository()
        pricingEngine = PricingEngine(repository: mockRepository)
        
        // Set up test data
        await setupTestData()
    }
    
    override func tearDown() async throws {
        pricingEngine = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Price Calculation Tests
    
    func testBasicPriceCalculation() async throws {
        // Given
        let serviceType = createTestServiceType()
        
        // When
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: .gold14K,
            metalWeightGrams: 1.0,
            laborMinutes: 30,
            isRush: false,
            companyId: "test-company"
        )
        
        // Then
        XCTAssertEqual(result.breakdown.metalCost, 35.0) // 1.0g * $35/g
        XCTAssertEqual(result.breakdown.laborCost, 42.5) // 0.5h * $85/h
        XCTAssertEqual(result.baseCost, 87.5) // 35.0 + 42.5 + 10.0 (fixed fee)
        XCTAssertEqual(result.rushMultiplier, 1.0)
        XCTAssertGreaterThan(result.finalRetail, result.baseCost)
    }
    
    func testRushMultiplierApplication() async throws {
        // Given
        let serviceType = createTestServiceType()
        
        // When
        let normalResult = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: .gold14K,
            metalWeightGrams: 1.0,
            laborMinutes: 30,
            isRush: false,
            companyId: "test-company"
        )
        
        let rushResult = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: .gold14K,
            metalWeightGrams: 1.0,
            laborMinutes: 30,
            isRush: true,
            companyId: "test-company"
        )
        
        // Then
        XCTAssertEqual(normalResult.rushMultiplier, 1.0)
        XCTAssertEqual(rushResult.rushMultiplier, 1.5)
        XCTAssertEqual(rushResult.finalRetail, normalResult.baseRetail * 1.5)
        XCTAssertTrue(rushResult.notes.contains("Rush multiplier applied: 1.5×"))
    }
    
    func testMetalCostCalculation() async throws {
        // Given
        let serviceType = createTestServiceType()
        
        // When - Test different metal types
        let gold14KResult = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: .gold14K,
            metalWeightGrams: 2.0,
            laborMinutes: 30,
            isRush: false,
            companyId: "test-company"
        )
        
        let platinumResult = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: .platinum,
            metalWeightGrams: 2.0,
            laborMinutes: 30,
            isRush: false,
            companyId: "test-company"
        )
        
        // Then
        XCTAssertEqual(gold14KResult.breakdown.metalCost, 70.0) // 2.0g * $35/g
        XCTAssertEqual(platinumResult.breakdown.metalCost, 56.0) // 2.0g * $28/g
    }
    
    func testLaborCostCalculation() async throws {
        // Given
        let serviceType = createTestServiceType()
        
        // When - Test different labor times
        let result30min = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: nil,
            metalWeightGrams: nil,
            laborMinutes: 30,
            isRush: false,
            companyId: "test-company"
        )
        
        let result60min = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: nil,
            metalWeightGrams: nil,
            laborMinutes: 60,
            isRush: false,
            companyId: "test-company"
        )
        
        // Then
        XCTAssertEqual(result30min.breakdown.laborCost, 42.5) // 0.5h * $85/h
        XCTAssertEqual(result60min.breakdown.laborCost, 85.0) // 1.0h * $85/h
    }
    
    func testNoMetalWork() async throws {
        // Given
        let serviceType = createTestServiceType()
        
        // When - Service without metal work
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: nil,
            metalWeightGrams: nil,
            laborMinutes: 15,
            isRush: false,
            companyId: "test-company"
        )
        
        // Then
        XCTAssertEqual(result.breakdown.metalCost, 0.0)
        XCTAssertTrue(result.notes.contains("No metal work required"))
    }
    
    func testMinimumChargeApplication() async throws {
        // Given
        let serviceType = createTestServiceType()
        
        // When - Very small service that should trigger minimum charge
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: nil,
            metalWeightGrams: nil,
            laborMinutes: 1, // Very small labor time
            isRush: false,
            companyId: "test-company"
        )
        
        // Then - Should apply minimum charge of $25
        XCTAssertEqual(result.finalRetail, 25.0)
        XCTAssertTrue(result.warnings.contains { $0.contains("Applied minimum charge") })
    }
    
    func testNonPreciousMetalHandling() async throws {
        // Given
        let serviceType = createTestServiceType()
        
        // When - Using non-precious metal
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: .stainlessSteel,
            metalWeightGrams: 5.0,
            laborMinutes: 30,
            isRush: false,
            companyId: "test-company"
        )
        
        // Then
        XCTAssertEqual(result.breakdown.metalCost, 0.0) // Non-precious metals don't use market rates
        XCTAssertTrue(result.notes.contains("Metal type Stainless Steel uses fixed pricing"))
    }
    
    // MARK: - Error Handling Tests
    
    func testMissingPricingRule() async throws {
        // Given
        mockRepository.shouldReturnEmptyPricingRules = true
        let serviceType = createTestServiceType()
        
        // When/Then
        do {
            _ = try await pricingEngine.calculatePrice(
                serviceType: serviceType,
                metalType: .gold14K,
                metalWeightGrams: 1.0,
                laborMinutes: 30,
                isRush: false,
                companyId: "test-company"
            )
            XCTFail("Expected PricingEngineError.noPricingRuleFound")
        } catch PricingEngineError.noPricingRuleFound {
            // Expected error
        }
    }
    
    func testMissingMetalRate() async throws {
        // Given
        mockRepository.shouldReturnEmptyMetalRates = true
        let serviceType = createTestServiceType()
        
        // When
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: .gold14K,
            metalWeightGrams: 1.0,
            laborMinutes: 30,
            isRush: false,
            companyId: "test-company"
        )
        
        // Then - Should have warning about missing rate
        XCTAssertTrue(result.warnings.contains { $0.contains("No market rate found for 14K Gold") })
        XCTAssertEqual(result.breakdown.metalCost, 0.0)
    }
    
    // MARK: - Helper Methods
    
    private func setupTestData() async {
        // Set up test pricing rule
        let formula = PricingFormula(
            metalMarkupPercentage: 2.0,    // 200% markup
            laborMarkupPercentage: 1.5,    // 150% markup
            fixedFee: 10.0,                // $10 fixed fee
            rushMultiplier: 1.5,           // 1.5x for rush
            minimumCharge: 25.0            // $25 minimum
        )
        
        let pricingRule = PricingRule(
            companyId: "test-company",
            name: "Test Pricing Rule",
            description: "Test pricing",
            formulaDefinition: formula
        )
        
        // Set up test metal rates
        let gold14KRate = MetalMarketRate(
            companyId: "test-company",
            metalType: .gold14K,
            rate: 35.0
        )
        
        let platinumRate = MetalMarketRate(
            companyId: "test-company",
            metalType: .platinum,
            rate: 28.0
        )
        
        // Set up test labor rate
        let laborRate = LaborRate(
            companyId: "test-company",
            role: .benchJeweler,
            ratePerHour: 85.0
        )
        
        await mockRepository.addTestData(
            pricingRules: [pricingRule],
            metalRates: [gold14KRate, platinumRate],
            laborRates: [laborRate]
        )
    }
    
    private func createTestServiceType() -> ServiceType {
        return ServiceType(
            companyId: "test-company",
            name: "Test Service",
            category: .jewelryRepair,
            defaultSku: "TEST",
            defaultLaborMinutes: 30,
            baseRetail: 50.0,
            baseCost: 20.0
        )
    }
}
