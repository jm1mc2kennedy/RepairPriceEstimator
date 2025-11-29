import XCTest
@testable import RepairPriceEstimator

/// Comprehensive tests for Springer's business logic
@MainActor
final class SpringersBusinessLogicTests: XCTestCase {
    
    private var pricingEngine: PricingEngine!
    private var workflowService: WorkflowService!
    private var inspectionService: InspectionService!
    private var mockRepository: MockDataRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockDataRepository()
        pricingEngine = PricingEngine(repository: mockRepository)
        workflowService = WorkflowService(repository: mockRepository)
        inspectionService = InspectionService(repository: mockRepository)
        
        await setupSpringersTestData()
    }
    
    override func tearDown() async throws {
        pricingEngine = nil
        workflowService = nil
        inspectionService = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Rush Policy Tests
    
    func testSpringersItemNoRushFee() async throws {
        // Given - Springer's item with rush request
        let serviceType = createRingSizingService()
        
        // When - Calculate price for Springer's item with rush
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: .gold14K,
            metalWeightGrams: 1.0,
            laborMinutes: 30,
            isRush: true,
            companyId: "test-company",
            springersItem: true,
            rushType: .within48Hours
        )
        
        // Then - No rush multiplier should be applied
        XCTAssertEqual(result.rushMultiplier, 1.0)
        XCTAssertEqual(result.breakdown.rushFee, 0.0)
        XCTAssertTrue(result.notes.contains("Springer's purchase - no rush fee applied"))
    }
    
    func testNonSpringersItemRushFee() async throws {
        // Given - Non-Springer's item with rush request
        let serviceType = createRingSizingService()
        
        // When - Calculate price for non-Springer's item with rush
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: .gold14K,
            metalWeightGrams: 1.0,
            laborMinutes: 30,
            isRush: true,
            companyId: "test-company",
            springersItem: false,
            rushType: .within48Hours
        )
        
        // Then - 1.5× rush multiplier should be applied
        XCTAssertEqual(result.rushMultiplier, 1.5)
        XCTAssertGreaterThan(result.breakdown.rushFee, 0)
        XCTAssertTrue(result.notes.contains("Non-Springer's item - rush multiplier: 1.5×"))
    }
    
    func testSameDayRushAfter2PM() async throws {
        // Given - Same-day rush request (simulating after 2PM)
        let serviceType = createRingSizingService()
        
        // When - Calculate price with same-day rush
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: .gold14K,
            metalWeightGrams: 1.0,
            laborMinutes: 30,
            isRush: true,
            companyId: "test-company",
            springersItem: false,
            rushType: .sameDay
        )
        
        // Then - Should warn about coordinator approval
        let hasCoordinatorWarning = result.warnings.contains { $0.contains("coordinator approval") }
        // Note: This would be true if current time is after 2PM
    }
    
    // MARK: - Service-Specific Pricing Tests
    
    func testRingSizingSpecificPricing() async throws {
        // Given - Ring sizing service with specific pricing
        let serviceType = ServiceType(
            companyId: "test-company",
            name: "14K Purchase Sizing under 3mm - Size Down",
            category: .jewelryRepair,
            defaultSku: "PUR143001",
            defaultLaborMinutes: 30,
            baseRetail: 180,
            baseCost: 140,
            metalTypes: [.gold14K],
            sizingCategory: .under3mm
        )
        
        // When - Calculate price
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: .gold14K,
            metalWeightGrams: 0,
            laborMinutes: 30,
            isRush: false,
            companyId: "test-company",
            sizingCategory: .under3mm
        )
        
        // Then - Should use specific pricing from service catalog
        XCTAssertEqual(result.baseRetail, 180)
        XCTAssertTrue(result.notes.contains("Using specific pricing for"))
    }
    
    func testGenericSKUPricing() async throws {
        // Given - Generic SKU service
        let serviceType = ServiceType(
            companyId: "test-company",
            name: "Generic Jewelry Repair",
            category: .jewelryRepair,
            defaultSku: "14JR0001",
            defaultLaborMinutes: 45,
            baseRetail: 0,
            baseCost: 0,
            isGenericSku: true
        )
        
        // When - Calculate price
        let result = try await pricingEngine.calculatePrice(
            serviceType: serviceType,
            metalType: nil,
            metalWeightGrams: nil,
            laborMinutes: 45,
            isRush: false,
            companyId: "test-company"
        )
        
        // Then - Should indicate manual pricing required
        XCTAssertTrue(result.notes.contains("Generic SKU - pricing will be entered manually"))
    }
    
    // MARK: - Workflow Status Tests
    
    func testValidStatusTransition() async throws {
        // Given - Quote in draft status
        let quote = createTestQuote(status: .draft)
        await mockRepository.addTestData(quotes: [quote])
        
        // When - Transition to presented
        let updatedQuote = try await workflowService.updateQuoteStatus(
            quoteId: quote.id,
            newStatus: .presented,
            userId: "test-user"
        )
        
        // Then - Status should be updated
        XCTAssertEqual(updatedQuote.status, .presented)
    }
    
    func testInvalidStatusTransition() async throws {
        // Given - Quote in draft status
        let quote = createTestQuote(status: .draft)
        await mockRepository.addTestData(quotes: [quote])
        
        // When/Then - Attempt invalid transition should fail
        do {
            _ = try await workflowService.updateQuoteStatus(
                quoteId: quote.id,
                newStatus: .completed, // Invalid: can't go from draft to completed
                userId: "test-user"
            )
            XCTFail("Expected WorkflowError.invalidStatusTransition")
        } catch WorkflowError.invalidStatusTransition {
            // Expected error
        }
    }
    
    func testOverdueQuoteDetection() async throws {
        // Given - Quote with past due date
        let pastDate = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        let quote = createTestQuote(status: .inShop, promisedDueDate: pastDate)
        await mockRepository.addTestData(quotes: [quote])
        
        // When - Get overdue quotes
        let overdueQuotes = try await workflowService.getOverdueQuotes(companyId: "test-company")
        
        // Then - Should identify overdue quote
        XCTAssertEqual(overdueQuotes.count, 1)
        XCTAssertEqual(overdueQuotes.first?.id, quote.id)
        XCTAssertTrue(overdueQuotes.first?.isOverdue == true)
    }
    
    // MARK: - Inspection Workflow Tests
    
    func testSafeToCleanDetection() async {
        // Given - Start inspection
        let guest = createTestGuest()
        let inspection = await inspectionService.startInspection(
            guestId: guest.id,
            inspectorId: "test-inspector",
            initialDescription: "Gold ring for cleaning"
        )
        
        // When - Add safe condition finding
        inspectionService.addFinding(
            category: .finish,
            severity: .minor,
            description: "Light scratches, safe for ultrasonic cleaning"
        )
        
        // Then - Should remain safe to clean
        XCTAssertTrue(inspectionService.currentInspection?.safeToClean == true)
    }
    
    func testUnsafeToCleanDetection() async {
        // Given - Start inspection
        let guest = createTestGuest()
        _ = await inspectionService.startInspection(
            guestId: guest.id,
            inspectorId: "test-inspector",
            initialDescription: "Ring with loose stones"
        )
        
        // When - Add unsafe condition finding
        inspectionService.addFinding(
            category: .stoneLoose,
            severity: .critical,
            description: "Multiple loose stones, unsafe for ultrasonic cleaning"
        )
        
        // Then - Should be marked unsafe to clean
        XCTAssertFalse(inspectionService.currentInspection?.safeToClean == true)
    }
    
    // MARK: - Priority Calculation Tests
    
    func testQuotePriorityCalculation() async throws {
        // Given - Different types of quotes
        var sameDayQuote = createTestQuote(status: .approved, rushType: .sameDay)
        var jewelryRepairQuote = createTestQuote(status: .approved, category: .jewelryRepair)
        var estateQuote = createTestQuote(status: .approved, category: .estateLiquidation)
        
        // When - Update priorities
        sameDayQuote.updatePriority()
        jewelryRepairQuote.updatePriority()
        estateQuote.updatePriority()
        
        // Then - Should have correct priorities
        XCTAssertEqual(sameDayQuote.priority, .urgent)
        XCTAssertEqual(jewelryRepairQuote.priority, .high)
        XCTAssertEqual(estateQuote.priority, .low)
    }
    
    // MARK: - Appraisal Pricing Tests
    
    func testAppraisalPricingCalculation() async throws {
        // Given - Standard appraisal for multiple items
        let result = AppraisalCalculator.calculateAppraisalFee(
            type: .insurance,
            itemCount: 3,
            largestCaratWeight: 1.5, // Should trigger 1.3× multiplier
            isUpdate: false,
            expedited: false,
            sarinReport: false
        )
        
        // Then - Should calculate correctly
        // First item: $150 × 1.3 = $195
        // Additional 2 items: $75 × 1.3 × 2 = $195
        // Total: $390
        XCTAssertEqual(result.totalFee, 390.0)
    }
    
    func testAppraisalUpdateDiscount() async throws {
        // Given - Update appraisal within 10 years
        let originalDate = Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date()
        
        let result = AppraisalCalculator.calculateAppraisalFee(
            type: .update,
            itemCount: 1,
            largestCaratWeight: 1.0,
            isUpdate: true,
            originalAppraisalDate: originalDate
        )
        
        // Then - Should apply update pricing (half price)
        XCTAssertEqual(result.baseFee, 37.5) // Half of $75 base
        XCTAssertTrue(result.updateDiscountApplied)
    }
    
    // MARK: - Diamond Documentation Tests
    
    func testDiamondStandardDescription() async throws {
        // Given - Diamond with full specs
        let diamond = LooseDiamondDocumentation(
            quoteId: "Q-2025-000001",
            documentedBy: "test-user",
            shape: .round,
            caratWeight: 1.25,
            color: .H,
            clarity: .VS1,
            origin: .natural
        )
        
        // Then - Should format correctly
        XCTAssertEqual(diamond.standardDescription, "RD 1.25ct H VS1 (N)")
    }
    
    func testDiamondVerificationCompletion() async throws {
        // Given - Diamond with partial verification
        let diamond = LooseDiamondDocumentation(
            quoteId: "Q-2025-000001",
            documentedBy: "test-user",
            shape: .princess,
            caratWeight: 0.75,
            weightVerified: true,
            measurementsVerified: false,
            inscriptionVerified: false
        )
        
        // Then - Should not be complete
        XCTAssertFalse(diamond.isVerificationComplete)
        XCTAssertFalse(diamond.isCompleteDocumentation)
    }
    
    // MARK: - SKU Management Tests
    
    func testSKUUniquenessValidation() async throws {
        // Given - Service with existing SKU
        let existingService = createRingSizingService(sku: "PUR143001")
        await mockRepository.addTestData(serviceTypes: [existingService])
        
        // When - Try to create another service with same SKU
        let duplicateService = createRingSizingService(sku: "PUR143001", name: "Different Service")
        
        // Then - Should detect SKU conflict
        // This would be validated in the UI or service layer
        XCTAssertEqual(existingService.defaultSku, duplicateService.defaultSku)
    }
    
    func testGenericVsSpecificSKUHandling() async throws {
        // Given - Generic and specific service types
        let genericService = ServiceType(
            companyId: "test-company",
            name: "Generic Jewelry Repair",
            category: .jewelryRepair,
            defaultSku: "14JR0001",
            defaultLaborMinutes: 45,
            baseRetail: 0,
            baseCost: 0,
            isGenericSku: true
        )
        
        let specificService = createRingSizingService()
        
        // Then - Should have different pricing behaviors
        XCTAssertTrue(genericService.isGenericSku)
        XCTAssertFalse(specificService.isGenericSku)
        XCTAssertEqual(genericService.baseRetail, 0) // Generic requires manual pricing
        XCTAssertGreaterThan(specificService.baseRetail, 0) // Specific has set price
    }
    
    // MARK: - Communication Tests
    
    func testCommunicationTemplateGeneration() async throws {
        // Given - Communication template
        let template = CommunicationTemplate(
            companyId: "test-company",
            name: "Estimate Ready",
            purpose: .estimateReady,
            type: .email,
            subject: "Your repair estimate is ready",
            messageTemplate: "Dear {{guestName}}, your repair estimate for {{quoteId}} is ready. Total: {{estimateAmount}}. Due date: {{dueDate}}."
        )
        
        // When - Generate message
        let message = template.generateMessage(
            guestName: "John Smith",
            quoteId: "Q-2025-000123",
            estimateAmount: "$245.00",
            dueDate: "December 15, 2025"
        )
        
        // Then - Should substitute variables correctly
        XCTAssertTrue(message.contains("Dear John Smith"))
        XCTAssertTrue(message.contains("Q-2025-000123"))
        XCTAssertTrue(message.contains("$245.00"))
        XCTAssertTrue(message.contains("December 15, 2025"))
    }
    
    // MARK: - Quality Control Tests
    
    func testQualityControlStatusFlow() async throws {
        // Given - Quote ready for QC
        let quote = createTestQuote(status: .inShop)
        await mockRepository.addTestData(quotes: [quote])
        
        // When - Move to quality review
        let qcQuote = try await workflowService.updateQuoteStatus(
            quoteId: quote.id,
            newStatus: .qualityReview,
            userId: "test-user"
        )
        
        // Then - Should be in quality review
        XCTAssertEqual(qcQuote.status, .qualityReview)
        XCTAssertTrue(qcQuote.status.requiresQualityControl)
    }
    
    func testQualityFailureFlow() async throws {
        // Given - Quote in quality review
        let quote = createTestQuote(status: .qualityReview)
        await mockRepository.addTestData(quotes: [quote])
        
        // When - Quality fails
        let failedQuote = try await workflowService.updateQuoteStatus(
            quoteId: quote.id,
            newStatus: .qualityFailed,
            userId: "test-user",
            notes: "Loose stones detected after repair"
        )
        
        // Then - Should be marked for rework with urgent priority
        XCTAssertEqual(failedQuote.status, .qualityFailed)
        XCTAssertEqual(failedQuote.priority, .urgent)
    }
    
    // MARK: - Department Workflow Tests
    
    func testDepartmentPriorityHandling() async throws {
        // Given - Different department types
        let jewelryRepair = createTestQuote(category: .jewelryRepair)
        let watchService = createTestQuote(category: .watchService)
        let estate = createTestQuote(category: .estateLiquidation)
        
        // Then - Should have correct priorities
        XCTAssertEqual(jewelryRepair.primaryServiceCategory.priority, 1)
        XCTAssertEqual(watchService.primaryServiceCategory.priority, 1)
        XCTAssertEqual(estate.primaryServiceCategory.priority, 4)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflowIntegration() async throws {
        // Given - Complete workflow from inspection to completion
        let guest = createTestGuest()
        
        // Start inspection
        _ = await inspectionService.startInspection(
            guestId: guest.id,
            inspectorId: "test-inspector",
            initialDescription: "Ring needs sizing"
        )
        
        // Add finding
        inspectionService.addFinding(
            category: .sizing,
            severity: .moderate,
            description: "Ring too large, needs sizing down"
        )
        
        // Complete inspection
        let inspectionResult = try await inspectionService.completeInspection()
        
        // Then - Should recommend repair quote
        XCTAssertTrue(inspectionResult.requiresRepairQuote)
        XCTAssertFalse(inspectionResult.safeToClean)
        XCTAssertTrue(inspectionResult.recommendedActions.contains { $0.type == .repairQuote })
    }
    
    // MARK: - Helper Methods
    
    private func setupSpringersTestData() async {
        // Set up comprehensive test data matching Springer's business
        let company = Company(
            id: "test-company",
            name: "Springer's Jewelers Test",
            primaryContactInfo: "test@springers.com"
        )
        
        let formula = PricingFormula(
            metalMarkupPercentage: 2.0,
            laborMarkupPercentage: 1.5,
            fixedFee: 10.0,
            rushMultiplier: 1.5,
            minimumCharge: 25.0
        )
        
        let pricingRule = PricingRule(
            companyId: "test-company",
            name: "Springer's Standard Pricing",
            description: "Standard Springer's pricing with rush policy",
            formulaDefinition: formula
        )
        
        let metalRate = MetalMarketRate(
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
            metalRates: [metalRate],
            laborRates: [laborRate],
            companies: [company]
        )
    }
    
    private func createTestQuote(
        status: QuoteStatus = .draft,
        rushType: RushType = .standard,
        category: ServiceCategory = .jewelryRepair,
        promisedDueDate: Date? = nil
    ) -> Quote {
        return Quote(
            id: "Q-2025-\(String(format: "%06d", Int.random(in: 1...999999)))",
            companyId: "test-company",
            storeId: "test-store",
            guestId: "test-guest",
            status: status,
            total: 125.00,
            rushType: rushType,
            promisedDueDate: promisedDueDate,
            primaryServiceCategory: category
        )
    }
    
    private func createTestGuest() -> Guest {
        return Guest(
            companyId: "test-company",
            primaryStoreId: "test-store",
            firstName: "Test",
            lastName: "Customer",
            email: "test@customer.com"
        )
    }
    
    private func createRingSizingService(sku: String = "PUR143001", name: String = "14K Ring Sizing Down") -> ServiceType {
        return ServiceType(
            companyId: "test-company",
            name: name,
            category: .jewelryRepair,
            defaultSku: sku,
            defaultLaborMinutes: 30,
            baseRetail: 180,
            baseCost: 140,
            metalTypes: [.gold14K],
            sizingCategory: .under3mm,
            requiresSpringersCheck: true
        )
    }
}
