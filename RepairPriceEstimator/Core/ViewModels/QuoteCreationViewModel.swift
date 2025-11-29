import Foundation
import SwiftUI

/// ViewModel for managing the multi-step quote creation workflow
@MainActor
final class QuoteCreationViewModel: ObservableObject {
    nonisolated(unsafe) private let repository: DataRepository
    private let authService: AuthService
    private let pricingEngine: PricingEngine
    private let quoteIDGenerator: QuoteIDGenerator
    private let photoUploadService: PhotoUploadService
    
    @Published var currentStep: Int = 1
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // Step 1: Guest Selection
    @Published var selectedGuest: Guest?
    @Published var availableGuests: [Guest] = []
    @Published var guestSearchText: String = ""
    
    // Step 2: Store Selection
    @Published var selectedStore: Store?
    @Published var availableStores: [Store] = []
    
    // Step 3: Line Items
    @Published var lineItems: [QuoteLineItemDraft] = []
    @Published var availableServiceTypes: [ServiceType] = []
    
    // Step 4: Photos
    @Published var photos: [QuotePhotoDraft] = []
    
    // Step 5: Review
    @Published var internalNotes: String = ""
    @Published var customerFacingNotes: String = ""
    @Published var isRush: Bool = false
    @Published var rushType: RushType? = nil
    @Published var requestedDueDate: Date? = nil
    
    // Calculated totals
    @Published var subtotal: Decimal = 0
    @Published var tax: Decimal = 0
    @Published var total: Decimal = 0
    @Published var rushMultiplier: Decimal = 1.0
    
    let totalSteps = 5
    
    init(repository: DataRepository = CloudKitService.shared,
         authService: AuthService = AuthService.shared,
         pricingEngine: PricingEngine = PricingEngine(),
         quoteIDGenerator: QuoteIDGenerator = QuoteIDGenerator(),
         photoUploadService: PhotoUploadService = PhotoUploadService()) {
        self.repository = repository
        self.authService = authService
        self.pricingEngine = pricingEngine
        self.quoteIDGenerator = quoteIDGenerator
        self.photoUploadService = photoUploadService
    }
    
    // MARK: - Step Navigation
    
    func nextStep() {
        guard canProceedToNextStep else { return }
        if currentStep < totalSteps {
            currentStep += 1
            if currentStep == 2 {
                Task { await loadStores() }
            } else if currentStep == 3 {
                Task { await loadServiceTypes() }
                recalculateTotals()
            } else if currentStep == 5 {
                recalculateTotals()
            }
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    var canProceedToNextStep: Bool {
        switch currentStep {
        case 1: return selectedGuest != nil
        case 2: return selectedStore != nil
        case 3: return !lineItems.isEmpty
        case 4: return true // Photos are optional
        case 5: return true
        default: return false
        }
    }
    
    // MARK: - Step 1: Guest Selection
    
    func loadGuests() async {
        guard let session = authService.currentSession else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let predicate: NSPredicate
            if !guestSearchText.isEmpty {
                predicate = NSPredicate(format: "companyId == %@", session.company.id)
            } else {
                predicate = NSPredicate(format: "companyId == %@", session.company.id)
            }
            
            let sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true), NSSortDescriptor(key: "lastName", ascending: true)]
            var fetchedGuests = try await repository.query(Guest.self, predicate: predicate, sortDescriptors: sortDescriptors)
            
            // Filter by search text if provided
            if !guestSearchText.isEmpty {
                let searchLower = guestSearchText.lowercased()
                fetchedGuests = fetchedGuests.filter { guest in
                    guest.fullName.lowercased().contains(searchLower) ||
                    guest.email?.lowercased().contains(searchLower) == true ||
                    guest.phone?.contains(guestSearchText) == true
                }
            }
            
            availableGuests = fetchedGuests
        } catch {
            errorMessage = "Failed to load guests: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func selectGuest(_ guest: Guest) {
        selectedGuest = guest
    }
    
    func createNewGuest(_ guest: Guest) async throws {
        guard let session = authService.currentSession else {
            throw QuoteCreationError.notAuthenticated
        }
        
        let newGuest = Guest(
            companyId: session.company.id,
            primaryStoreId: session.primaryStore.id,
            firstName: guest.firstName,
            lastName: guest.lastName,
            email: guest.email,
            phone: guest.phone,
            notes: guest.notes
        )
        
        let savedGuest = try await repository.save(newGuest)
        selectedGuest = savedGuest
        availableGuests.append(savedGuest)
    }
    
    // MARK: - Step 2: Store Selection
    
    func loadStores() async {
        guard let session = authService.currentSession else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        availableStores = session.accessibleStores
        if selectedStore == nil {
            selectedStore = session.primaryStore
        }
    }
    
    func selectStore(_ store: Store) {
        selectedStore = store
    }
    
    // MARK: - Step 3: Line Items
    
    func loadServiceTypes() async {
        guard let session = authService.currentSession else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let predicate = NSPredicate(format: "companyId == %@ AND isActive == 1", session.company.id)
            let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            availableServiceTypes = try await repository.query(ServiceType.self, predicate: predicate, sortDescriptors: sortDescriptors)
        } catch {
            errorMessage = "Failed to load service types: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func addLineItem(serviceType: ServiceType, quantity: Int = 1, metalType: MetalType? = nil, metalWeightGrams: Decimal? = nil, isRush: Bool = false) {
        let lineItem = QuoteLineItemDraft(
            serviceType: serviceType,
            quantity: quantity,
            metalType: metalType,
            metalWeightGrams: metalWeightGrams,
            isRush: isRush
        )
        lineItems.append(lineItem)
        recalculateTotals()
    }
    
    func removeLineItem(at index: Int) {
        guard index < lineItems.count else { return }
        lineItems.remove(at: index)
        recalculateTotals()
    }
    
    func updateLineItem(at index: Int, quantity: Int? = nil, metalType: MetalType? = nil, metalWeightGrams: Decimal? = nil, isRush: Bool? = nil) {
        guard index < lineItems.count else { return }
        
        var item = lineItems[index]
        if let quantity = quantity { item.quantity = quantity }
        if let metalType = metalType { item.metalType = metalType }
        if let metalWeightGrams = metalWeightGrams { item.metalWeightGrams = metalWeightGrams }
        if let isRush = isRush { item.isRush = isRush }
        
        lineItems[index] = item
        recalculateTotals()
    }
    
    // MARK: - Step 4: Photos
    
    func addPhoto(_ photo: QuotePhotoDraft) {
        photos.append(photo)
    }
    
    func removePhoto(at index: Int) {
        guard index < photos.count else { return }
        photos.remove(at: index)
    }
    
    // MARK: - Step 5: Review & Save
    
    func recalculateTotals() {
        guard !lineItems.isEmpty else {
            subtotal = 0
            tax = 0
            total = 0
            return
        }
        
        var calculatedSubtotal: Decimal = 0
        
        // Calculate price for each line item using PricingEngine
        for item in lineItems {
            // For now, use base retail price. Full pricing calculation would require
            // metal rates and labor rates which should be fetched from repository
            let basePrice = item.serviceType.baseRetail
            let itemTotal = basePrice * Decimal(item.quantity)
            calculatedSubtotal += itemTotal
        }
        
        // Apply rush multiplier if any line item is rush or if quote-level rush is set
        if lineItems.contains(where: { $0.isRush }) || isRush {
            rushMultiplier = 1.5
        } else {
            rushMultiplier = 1.0
        }
        
        subtotal = calculatedSubtotal
        tax = subtotal * 0.08 // 8% tax (should be configurable)
        total = (subtotal * rushMultiplier) + tax
    }
    
    func saveQuote() async throws -> Quote {
        guard let session = authService.currentSession,
              let guest = selectedGuest,
              let store = selectedStore else {
            throw QuoteCreationError.incompleteData
        }
        
        guard !lineItems.isEmpty else {
            throw QuoteCreationError.noLineItems
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Generate unique Quote ID
            let quoteID = try await quoteIDGenerator.generateUniqueQuoteID(companyId: session.company.id)
            
            // Determine primary service category from line items
            let primaryCategory = lineItems.first?.serviceType.category ?? .jewelryRepair
            
            // Create quote
            var newQuote = Quote(
                id: quoteID,
                companyId: session.company.id,
                storeId: store.id,
                guestId: guest.id,
                status: .draft,
                subtotal: subtotal,
                tax: tax,
                total: total,
                rushMultiplierApplied: rushMultiplier,
                internalNotes: internalNotes.isEmpty ? nil : internalNotes,
                customerFacingNotes: customerFacingNotes.isEmpty ? nil : customerFacingNotes,
                springersItem: false, // TODO: Get from intake checklist if available
                rushType: rushType,
                requestedDueDate: requestedDueDate,
                primaryServiceCategory: primaryCategory
            )
            
            // Save quote
            let savedQuote = try await repository.save(newQuote)
            
            // Save line items
            for (index, itemDraft) in lineItems.enumerated() {
                let lineItem = QuoteLineItem(
                    quoteId: savedQuote.id,
                    serviceTypeId: itemDraft.serviceType.id,
                    sku: itemDraft.serviceType.defaultSku,
                    description: itemDraft.serviceType.name,
                    metalType: itemDraft.metalType,
                    metalWeightGrams: itemDraft.metalWeightGrams,
                    laborMinutes: itemDraft.serviceType.defaultLaborMinutes,
                    baseCost: itemDraft.serviceType.baseCost,
                    baseRetail: itemDraft.serviceType.baseRetail,
                    calculatedRetail: itemDraft.serviceType.baseRetail,
                    isRush: itemDraft.isRush,
                    rushMultiplier: itemDraft.isRush ? rushMultiplier : 1.0,
                    finalRetail: itemDraft.serviceType.baseRetail * (itemDraft.isRush ? rushMultiplier : 1.0)
                )
                _ = try await repository.save(lineItem)
            }
            
            // Upload and save photos
            for photoDraft in photos {
                do {
                    let uploadedPhoto = try await photoUploadService.uploadPhoto(
                        imageData: photoDraft.imageData,
                        quoteId: savedQuote.id,
                        caption: photoDraft.caption
                    )
                    // Photo is already saved in CloudKit by uploadPhoto, no need to save again
                    print("✅ Photo uploaded for quote: \(uploadedPhoto.id)")
                } catch {
                    print("⚠️ Failed to upload photo: \(error)")
                    // Continue with other photos even if one fails
                }
            }
            
            print("✅ Created quote: \(savedQuote.id)")
            return savedQuote
        } catch {
            print("❌ Error creating quote: \(error)")
            errorMessage = "Failed to create quote: \(error.localizedDescription)"
            showError = true
            throw error
        }
    }
}

// MARK: - Supporting Types

struct QuoteLineItemDraft: Identifiable {
    let id = UUID()
    var serviceType: ServiceType
    var quantity: Int
    var metalType: MetalType?
    var metalWeightGrams: Decimal?
    var isRush: Bool
    
    var totalPrice: Decimal {
        serviceType.baseRetail * Decimal(quantity)
    }
}

struct QuotePhotoDraft: Identifiable {
    let id = UUID()
    let imageData: Data
    var caption: String?
}

enum QuoteCreationError: LocalizedError {
    case notAuthenticated
    case incompleteData
    case noLineItems
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to create quotes"
        case .incompleteData:
            return "Please complete all required steps"
        case .noLineItems:
            return "At least one line item is required"
        case .saveFailed(let message):
            return "Failed to save quote: \(message)"
        }
    }
}

