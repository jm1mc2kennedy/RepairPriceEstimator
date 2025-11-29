import Foundation
@testable import RepairPriceEstimator

/// Mock implementation of DataRepository for testing
@MainActor
final class MockDataRepository: DataRepository {
    
    // MARK: - Test Data Storage
    private var pricingRules: [PricingRule] = []
    private var metalRates: [MetalMarketRate] = []
    private var laborRates: [LaborRate] = []
    private var serviceTypes: [ServiceType] = []
    private var companies: [Company] = []
    private var stores: [Store] = []
    private var users: [User] = []
    private var guests: [Guest] = []
    private var quotes: [Quote] = []
    private var quoteLineItems: [QuoteLineItem] = []
    private var quotePhotos: [QuotePhoto] = []
    
    // MARK: - Test Configuration
    var shouldReturnEmptyPricingRules = false
    var shouldReturnEmptyMetalRates = false
    var shouldReturnEmptyLaborRates = false
    var shouldThrowError = false
    var errorToThrow: Error?
    
    var isAvailable: Bool {
        get async { true }
    }
    
    // MARK: - DataRepository Implementation
    
    func save<T: CloudKitMappable>(_ item: T) async throws -> T {
        if shouldThrowError {
            throw errorToThrow ?? RepositoryError.unknownError(MockError.testError)
        }
        
        // Store the item based on its type
        switch item {
        case let pricingRule as PricingRule:
            pricingRules.removeAll { $0.id == pricingRule.id }
            pricingRules.append(pricingRule)
        case let metalRate as MetalMarketRate:
            metalRates.removeAll { $0.id == metalRate.id }
            metalRates.append(metalRate)
        case let laborRate as LaborRate:
            laborRates.removeAll { $0.id == laborRate.id }
            laborRates.append(laborRate)
        case let serviceType as ServiceType:
            serviceTypes.removeAll { $0.id == serviceType.id }
            serviceTypes.append(serviceType)
        case let company as Company:
            companies.removeAll { $0.id == company.id }
            companies.append(company)
        case let store as Store:
            stores.removeAll { $0.id == store.id }
            stores.append(store)
        case let user as User:
            users.removeAll { $0.id == user.id }
            users.append(user)
        case let guest as Guest:
            guests.removeAll { $0.id == guest.id }
            guests.append(guest)
        case let quote as Quote:
            quotes.removeAll { $0.id == quote.id }
            quotes.append(quote)
        case let lineItem as QuoteLineItem:
            quoteLineItems.removeAll { $0.id == lineItem.id }
            quoteLineItems.append(lineItem)
        case let photo as QuotePhoto:
            quotePhotos.removeAll { $0.id == photo.id }
            quotePhotos.append(photo)
        default:
            break
        }
        
        return item
    }
    
    func fetch<T: CloudKitMappable>(_ type: T.Type, id: String) async throws -> T? {
        if shouldThrowError {
            throw errorToThrow ?? RepositoryError.unknownError(MockError.testError)
        }
        
        switch type {
        case is PricingRule.Type:
            return pricingRules.first { $0.id == id } as? T
        case is MetalMarketRate.Type:
            return metalRates.first { $0.id == id } as? T
        case is LaborRate.Type:
            return laborRates.first { $0.id == id } as? T
        case is ServiceType.Type:
            return serviceTypes.first { $0.id == id } as? T
        case is Company.Type:
            return companies.first { $0.id == id } as? T
        case is Store.Type:
            return stores.first { $0.id == id } as? T
        case is User.Type:
            return users.first { $0.id == id } as? T
        case is Guest.Type:
            return guests.first { $0.id == id } as? T
        case is Quote.Type:
            return quotes.first { $0.id == id } as? T
        case is QuoteLineItem.Type:
            return quoteLineItems.first { $0.id == id } as? T
        case is QuotePhoto.Type:
            return quotePhotos.first { $0.id == id } as? T
        default:
            return nil
        }
    }
    
    func query<T: CloudKitMappable>(_ type: T.Type, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) async throws -> [T] {
        if shouldThrowError {
            throw errorToThrow ?? RepositoryError.unknownError(MockError.testError)
        }
        
        var results: [T] = []
        
        switch type {
        case is PricingRule.Type:
            if shouldReturnEmptyPricingRules {
                return []
            }
            results = pricingRules.compactMap { $0 as? T }
        case is MetalMarketRate.Type:
            if shouldReturnEmptyMetalRates {
                return []
            }
            results = metalRates.compactMap { $0 as? T }
        case is LaborRate.Type:
            if shouldReturnEmptyLaborRates {
                return []
            }
            results = laborRates.compactMap { $0 as? T }
        case is ServiceType.Type:
            results = serviceTypes.compactMap { $0 as? T }
        case is Company.Type:
            results = companies.compactMap { $0 as? T }
        case is Store.Type:
            results = stores.compactMap { $0 as? T }
        case is User.Type:
            results = users.compactMap { $0 as? T }
        case is Guest.Type:
            results = guests.compactMap { $0 as? T }
        case is Quote.Type:
            results = quotes.compactMap { $0 as? T }
        case is QuoteLineItem.Type:
            results = quoteLineItems.compactMap { $0 as? T }
        case is QuotePhoto.Type:
            results = quotePhotos.compactMap { $0 as? T }
        default:
            break
        }
        
        // Apply predicate filtering (simplified implementation)
        if let predicate = predicate {
            results = results.filter { item in
                // This is a simplified predicate evaluation
                // In a real implementation, you'd parse and evaluate the predicate properly
                return evaluatePredicate(predicate, on: item)
            }
        }
        
        // Apply sorting (simplified implementation)
        if let sortDescriptors = sortDescriptors, !sortDescriptors.isEmpty {
            // For simplicity, just return as-is. In real tests, you might want proper sorting.
        }
        
        return results
    }
    
    func delete<T: CloudKitMappable>(_ type: T.Type, id: String) async throws {
        if shouldThrowError {
            throw errorToThrow ?? RepositoryError.unknownError(MockError.testError)
        }
        
        switch type {
        case is PricingRule.Type:
            pricingRules.removeAll { $0.id == id }
        case is MetalMarketRate.Type:
            metalRates.removeAll { $0.id == id }
        case is LaborRate.Type:
            laborRates.removeAll { $0.id == id }
        case is ServiceType.Type:
            serviceTypes.removeAll { $0.id == id }
        case is Company.Type:
            companies.removeAll { $0.id == id }
        case is Store.Type:
            stores.removeAll { $0.id == id }
        case is User.Type:
            users.removeAll { $0.id == id }
        case is Guest.Type:
            guests.removeAll { $0.id == id }
        case is Quote.Type:
            quotes.removeAll { $0.id == id }
        case is QuoteLineItem.Type:
            quoteLineItems.removeAll { $0.id == id }
        case is QuotePhoto.Type:
            quotePhotos.removeAll { $0.id == id }
        default:
            break
        }
    }
    
    // MARK: - Test Helper Methods
    
    func addTestData(
        pricingRules: [PricingRule] = [],
        metalRates: [MetalMarketRate] = [],
        laborRates: [LaborRate] = [],
        serviceTypes: [ServiceType] = [],
        companies: [Company] = [],
        stores: [Store] = [],
        users: [User] = [],
        guests: [Guest] = [],
        quotes: [Quote] = [],
        quoteLineItems: [QuoteLineItem] = [],
        quotePhotos: [QuotePhoto] = []
    ) async {
        self.pricingRules.append(contentsOf: pricingRules)
        self.metalRates.append(contentsOf: metalRates)
        self.laborRates.append(contentsOf: laborRates)
        self.serviceTypes.append(contentsOf: serviceTypes)
        self.companies.append(contentsOf: companies)
        self.stores.append(contentsOf: stores)
        self.users.append(contentsOf: users)
        self.guests.append(contentsOf: guests)
        self.quotes.append(contentsOf: quotes)
        self.quoteLineItems.append(contentsOf: quoteLineItems)
        self.quotePhotos.append(contentsOf: quotePhotos)
    }
    
    func clearAllData() {
        pricingRules.removeAll()
        metalRates.removeAll()
        laborRates.removeAll()
        serviceTypes.removeAll()
        companies.removeAll()
        stores.removeAll()
        users.removeAll()
        guests.removeAll()
        quotes.removeAll()
        quoteLineItems.removeAll()
        quotePhotos.removeAll()
    }
    
    func reset() {
        clearAllData()
        shouldReturnEmptyPricingRules = false
        shouldReturnEmptyMetalRates = false
        shouldReturnEmptyLaborRates = false
        shouldThrowError = false
        errorToThrow = nil
    }
    
    // MARK: - Private Helper Methods
    
    private func evaluatePredicate<T>(_ predicate: NSPredicate, on item: T) -> Bool {
        // This is a very simplified predicate evaluation for testing
        // In a real implementation, you'd want more sophisticated predicate parsing
        
        let predicateString = predicate.predicateFormat
        
        // Handle common patterns used in tests
        if predicateString.contains("companyId == \"test-company\"") {
            // Check if the item has a companyId property matching "test-company"
            return checkPropertyValue(item, property: "companyId", value: "test-company")
        }
        
        if predicateString.contains("role == \"BENCH_JEWELER\"") {
            return checkPropertyValue(item, property: "role", value: "BENCH_JEWELER")
        }
        
        if predicateString.contains("metalType == \"GOLD_14K\"") {
            return checkPropertyValue(item, property: "metalType", value: "GOLD_14K")
        }
        
        if predicateString.contains("isActive == YES") {
            return checkPropertyValue(item, property: "isActive", value: true)
        }
        
        // Default to true for unhandled predicates
        return true
    }
    
    private func checkPropertyValue<T>(_ item: T, property: String, value: Any) -> Bool {
        let mirror = Mirror(reflecting: item)
        
        for child in mirror.children {
            if let label = child.label, label == property {
                // Handle different value types
                switch (child.value, value) {
                case (let itemValue as String, let expectedValue as String):
                    return itemValue == expectedValue
                case (let itemValue as Bool, let expectedValue as Bool):
                    return itemValue == expectedValue
                case (let itemValue as UserRole, let expectedString as String):
                    return itemValue.rawValue == expectedString
                case (let itemValue as MetalType, let expectedString as String):
                    return itemValue.rawValue == expectedString
                default:
                    return false
                }
            }
        }
        
        return false
    }
}

// MARK: - Mock Error

enum MockError: Error, LocalizedError {
    case testError
    
    var errorDescription: String? {
        switch self {
        case .testError:
            return "Test error for unit testing"
        }
    }
}
