import Foundation
import SwiftUI

/// ViewModel for managing quote lists with filtering and searching
@MainActor
final class QuoteListViewModel: ObservableObject {
    nonisolated(unsafe) private let repository: DataRepository
    private let authService: AuthService
    
    @Published var quotes: [Quote] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedStatus: QuoteStatus?
    @Published var showError: Bool = false
    
    init(repository: DataRepository = CloudKitService.shared, authService: AuthService = AuthService.shared) {
        self.repository = repository
        self.authService = authService
    }
    
    /// Load quotes from CloudKit with current filters
    func loadQuotes() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let session = authService.currentSession else {
            errorMessage = "Not authenticated"
            showError = true
            return
        }
        
        do {
            // Build predicate based on filters
            var predicates: [NSPredicate] = []
            
            // Company scope
            predicates.append(NSPredicate(format: "companyId == %@", session.company.id))
            
            // Status filter
            if let status = selectedStatus {
                predicates.append(NSPredicate(format: "status == %@", status.rawValue))
            }
            
            // Search filter (by Quote ID or guest name)
            if !searchText.isEmpty {
                // Note: CloudKit queries can't join Guest records easily
                // For now, search by Quote ID only. Guest name search would require
                // fetching quotes first then filtering by guest name in-memory
                predicates.append(NSPredicate(format: "id CONTAINS[cd] %@", searchText))
            }
            
            let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            let sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let fetchedQuotes = try await repository.query(Quote.self, predicate: combinedPredicate, sortDescriptors: sortDescriptors)
            
            // If searching by text and no results by ID, try filtering by guest names
            if !searchText.isEmpty && fetchedQuotes.isEmpty {
                // Load all quotes and filter by guest name in memory
                let allPredicates = predicates.dropLast() // Remove search predicate
                let allPredicate = allPredicates.isEmpty ? 
                    NSPredicate(format: "companyId == %@", session.company.id) :
                    NSCompoundPredicate(andPredicateWithSubpredicates: Array(allPredicates))
                
                let allQuotes = try await repository.query(Quote.self, predicate: allPredicate, sortDescriptors: sortDescriptors)
                
                // Fetch guests and filter
                let guestIds = Array(Set(allQuotes.map { $0.guestId }))
                var matchingQuoteIds: Set<String> = []
                
                for guestId in guestIds {
                    if let guest = try await repository.fetch(Guest.self, id: guestId) {
                        let fullName = guest.fullName.lowercased()
                        if fullName.contains(searchText.lowercased()) {
                            matchingQuoteIds.insert(guestId)
                        }
                    }
                }
                
                quotes = allQuotes.filter { matchingQuoteIds.contains($0.guestId) }
            } else {
                quotes = fetchedQuotes
            }
            
            print("✅ Loaded \(quotes.count) quote(s)")
        } catch {
            print("❌ Error loading quotes: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    /// Delete a quote (with permission check)
    func deleteQuote(_ quote: Quote) async {
        guard authService.hasPermission(for: .deleteQuotes) else {
            errorMessage = "You don't have permission to delete quotes"
            showError = true
            return
        }
        
        do {
            try await repository.delete(Quote.self, id: quote.id)
            quotes.removeAll { $0.id == quote.id }
            print("✅ Deleted quote: \(quote.id)")
        } catch {
            print("❌ Error deleting quote: \(error)")
            errorMessage = "Failed to delete quote: \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Refresh quotes (called by pull-to-refresh)
    func refresh() async {
        await loadQuotes()
    }
}

