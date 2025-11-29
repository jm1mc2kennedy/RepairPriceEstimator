import Foundation
import SwiftUI

/// ViewModel for managing a single quote and its operations
@MainActor
final class QuoteDetailViewModel: ObservableObject {
    nonisolated(unsafe) private let repository: DataRepository
    private let authService: AuthService
    private let workflowService: WorkflowService
    
    let quoteId: String
    
    @Published var quote: Quote?
    @Published var guest: Guest?
    @Published var store: Store?
    @Published var lineItems: [QuoteLineItem] = []
    @Published var photos: [QuotePhoto] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    init(quoteId: String, repository: DataRepository = CloudKitService.shared, authService: AuthService = AuthService.shared, workflowService: WorkflowService = WorkflowService.shared) {
        self.quoteId = quoteId
        self.repository = repository
        self.authService = authService
        self.workflowService = workflowService
    }
    
    /// Load quote details from CloudKit
    func loadQuoteDetails() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Load quote
            guard let loadedQuote = try await repository.fetch(Quote.self, id: quoteId) else {
                errorMessage = "Quote not found"
                showError = true
                return
            }
            
            quote = loadedQuote
            
            // Load guest
            if let loadedGuest = try await repository.fetch(Guest.self, id: loadedQuote.guestId) {
                guest = loadedGuest
            }
            
            // Load store
            if let loadedStore = try await repository.fetch(Store.self, id: loadedQuote.storeId) {
                store = loadedStore
            }
            
            // Load line items
            let lineItemPredicate = NSPredicate(format: "quoteId == %@", quoteId)
            let lineItemSort = [NSSortDescriptor(key: "id", ascending: true)]
            lineItems = try await repository.query(QuoteLineItem.self, predicate: lineItemPredicate, sortDescriptors: lineItemSort)
            
            // Load photos
            let photoPredicate = NSPredicate(format: "quoteId == %@", quoteId)
            let photoSort = [NSSortDescriptor(key: "createdAt", ascending: true)]
            photos = try await repository.query(QuotePhoto.self, predicate: photoPredicate, sortDescriptors: photoSort)
            
            print("✅ Loaded quote details for: \(quoteId)")
        } catch {
            print("❌ Error loading quote details: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    /// Update quote status
    func updateStatus(_ newStatus: QuoteStatus) async {
        guard let currentQuote = quote else { return }
        
        do {
            // Use workflow service to update status (handles validation and logging)
            if let session = authService.currentSession {
                let updatedQuote = try await workflowService.updateQuoteStatus(
                    quoteId: quoteId,
                    newStatus: newStatus,
                    userId: session.user.id,
                    notes: nil
                )
                quote = updatedQuote
                print("✅ Updated quote status to: \(newStatus.displayName)")
            } else {
                // Fallback: validate and save directly
                guard currentQuote.status.possibleNextStatuses.contains(newStatus) else {
                    errorMessage = "Invalid status transition from \(currentQuote.status.displayName) to \(newStatus.displayName)"
                    showError = true
                    return
                }
                
                var updatedQuote = currentQuote
                updatedQuote.status = newStatus
                updatedQuote.updatedAt = Date()
                
                quote = try await repository.save(updatedQuote)
                print("✅ Updated quote status to: \(newStatus.displayName)")
            }
        } catch {
            print("❌ Error updating quote status: \(error)")
            errorMessage = "Failed to update status: \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Delete quote
    func deleteQuote() async {
        guard let currentQuote = quote else { return }
        guard authService.hasPermission(for: .deleteQuotes) else {
            errorMessage = "You don't have permission to delete quotes"
            showError = true
            return
        }
        
        do {
            // Delete associated line items
            for lineItem in lineItems {
                try await repository.delete(QuoteLineItem.self, id: lineItem.id)
            }
            
            // Delete associated photos
            for photo in photos {
                try await repository.delete(QuotePhoto.self, id: photo.id)
            }
            
            // Delete quote
            try await repository.delete(Quote.self, id: quoteId)
            
            print("✅ Deleted quote: \(quoteId)")
        } catch {
            print("❌ Error deleting quote: \(error)")
            errorMessage = "Failed to delete quote: \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Update quote notes
    func updateNotes(internalNotes: String?, customerFacingNotes: String?) async {
        guard var currentQuote = quote else { return }
        
        do {
            currentQuote.internalNotes = internalNotes
            currentQuote.customerFacingNotes = customerFacingNotes
            currentQuote.updatedAt = Date()
            
            quote = try await repository.save(currentQuote)
            print("✅ Updated quote notes")
        } catch {
            print("❌ Error updating notes: \(error)")
            errorMessage = "Failed to update notes: \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Refresh quote details
    func refresh() async {
        await loadQuoteDetails()
    }
}

