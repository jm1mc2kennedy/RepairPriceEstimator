import XCTest
@testable import RepairPriceEstimator

/// Specific tests for rush multiplier functionality
@MainActor
final class RushMultiplierTests: XCTestCase {
    
    private var pricingEngine: PricingEngine!
    private var mockRepository: MockDataRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockDataRepository()
        pricingEngine = PricingEngine(repository: mockRepository)
        
        await setupTestData()
    }
    
    override func tearDown() async throws {
        pricingEngine = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Rush Multiplier Tests
    
    func testStandardRushMultiplier() async throws {
        // Given
        let serviceType = createTestServiceType()
        
        // When
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: .gold14K,
            metalWeightGrams: 1.0,
            laborMinutes: 30,
            isRush: true,
            companyId: "test-company"
        )
        
        // Then - Should apply 1.5x rush multiplier
        XCTAssertEqual(result.rushMultiplier, 1.5)
        XCTAssertGreaterThan(result.breakdown.rushFee, 0)
        XCTAssertTrue(result.notes.contains("Rush multiplier applied: 1.5×"))
    }
    
    func testNoRushMultiplierForStandardService() async throws {
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
        
        // Then - Should not apply rush multiplier
        XCTAssertEqual(result.rushMultiplier, 1.0)
        XCTAssertEqual(result.breakdown.rushFee, 0.0)
        XCTAssertFalse(result.notes.contains { $0.contains("Rush multiplier") })
    }
    
    func testRushVsStandardPriceComparison() async throws {
        // Given
        let serviceType = createTestServiceType()
        
        // When
        let standardResult = try await pricingEngine.calculatePrice(
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
        let expectedRushPrice = standardResult.baseRetail * 1.5
        XCTAssertEqual(rushResult.finalRetail, expectedRushPrice, accuracy: 0.01)
        
        // Rush fee should be the difference
        let expectedRushFee = expectedRushPrice - standardResult.baseRetail
        XCTAssertEqual(rushResult.breakdown.rushFee, expectedRushFee, accuracy: 0.01)
    }
    
    func testRushMultiplierWithMinimumCharge() async throws {
        // Given
        let serviceType = createTestServiceType()
        
        // When - Very small service with rush
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: nil,
            metalWeightGrams: nil,
            laborMinutes: 1, // Very small labor
            isRush: true,
            companyId: "test-company"
        )
        
        // Then - Minimum charge should still apply even with rush
        XCTAssertEqual(result.finalRetail, 25.0) // Minimum charge
        XCTAssertTrue(result.warnings.contains { $0.contains("Applied minimum charge") })
        XCTAssertEqual(result.rushMultiplier, 1.5) // Rush multiplier was applied before minimum
    }
    
    func testRushMultiplierCalculationAccuracy() async throws {
        // Given
        let serviceType = createTestServiceType()
        
        // When
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: .gold14K,
            metalWeightGrams: 2.5, // Specific amount for precise calculation
            laborMinutes: 45,      // 0.75 hours
            isRush: true,
            companyId: "test-company"
        )
        
        // Then - Verify precise calculation
        let expectedMetalCost = Decimal(2.5) * 35.0 // $87.50
        let expectedLaborCost = Decimal(0.75) * 85.0 // $63.75
        let expectedBaseCost = expectedMetalCost + expectedLaborCost + 10.0 // $161.25
        
        let expectedMaterialMarkup = expectedMetalCost * 2.0 // $175.00
        let expectedLaborMarkup = expectedLaborCost * 1.5 // $95.625
        let expectedBaseRetail = expectedBaseCost + expectedMaterialMarkup + expectedLaborMarkup // $431.875
        
        let expectedFinalRetail = expectedBaseRetail * 1.5 // $647.8125
        
        XCTAssertEqual(result.breakdown.metalCost, expectedMetalCost)
        XCTAssertEqual(result.breakdown.laborCost, expectedLaborCost)
        XCTAssertEqual(result.baseCost, expectedBaseCost)
        XCTAssertEqual(result.baseRetail, expectedBaseRetail, accuracy: 0.01)
        XCTAssertEqual(result.finalRetail, expectedFinalRetail, accuracy: 0.01)
    }
    
    func testCustomRushMultiplier() async throws {
        // Given - Custom pricing rule with different rush multiplier
        let customFormula = PricingFormula(
            metalMarkupPercentage: 2.0,
            laborMarkupPercentage: 1.5,
            fixedFee: 10.0,
            rushMultiplier: 2.0, // 2x rush multiplier instead of 1.5x
            minimumCharge: 25.0
        )
        
        let customPricingRule = PricingRule(
            id: "custom-rule",
            companyId: "test-company",
            name: "Custom Rush Rule",
            description: "Custom pricing with 2x rush",
            formulaDefinition: customFormula
        )
        
        await mockRepository.addTestData(
            pricingRules: [customPricingRule],
            metalRates: [],
            laborRates: []
        )
        
        let serviceType = ServiceType(
            companyId: "test-company",
            name: "Custom Service",
            category: .jewelryRepair,
            defaultSku: "CUSTOM",
            defaultLaborMinutes: 30,
            baseRetail: 50.0,
            baseCost: 20.0,
            pricingFormulaId: "custom-rule" // Use custom rule
        )
        
        // When
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: nil,
            metalWeightGrams: nil,
            laborMinutes: 60,
            isRush: true,
            companyId: "test-company"
        )
        
        // Then - Should use 2x rush multiplier
        XCTAssertEqual(result.rushMultiplier, 2.0)
        XCTAssertTrue(result.notes.contains("Rush multiplier applied: 2.0×"))
    }
    
    // MARK: - Helper Methods
    
    private func setupTestData() async {
        let formula = PricingFormula(
            metalMarkupPercentage: 2.0,
            laborMarkupPercentage: 1.5,
            fixedFee: 10.0,
            rushMultiplier: 1.5,
            minimumCharge: 25.0
        )
        
        let pricingRule = PricingRule(
            companyId: "test-company",
            name: "Standard Pricing Rule",
            description: "Standard pricing with 1.5x rush",
            formulaDefinition: formula
        )
        
        let gold14KRate = MetalMarketRate(
            companyId: "test-company",
            metalType: .gold14K,
            rate: 35.0
        )
        
        let laborRate = LaborRate(
            companyId: "test-company",
            role: .benchJeweler,
            ratePerHour: 85.0
        )
        
        await mockRepository.addTestData(
            pricingRules: [pricingRule],
            metalRates: [gold14KRate],
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
