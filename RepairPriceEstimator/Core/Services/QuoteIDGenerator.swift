import Foundation

/// Service for generating unique human-readable Quote IDs
@MainActor
final class QuoteIDGenerator {
    nonisolated(unsafe) private let repository: DataRepository
    private static let idPrefix = "Q"
    private static let sequenceLength = 6 // Results in 000001, 000002, etc.
    
    init(repository: DataRepository = CloudKitService.shared) {
        self.repository = repository
    }
    
    /// Generate a unique Quote ID in the format Q-YYYY-NNNNNN
    func generateUniqueQuoteID(companyId: String) async throws -> String {
        let currentYear = Calendar.current.component(.year, from: Date())
        
        // Get the next sequence number for this year
        let sequenceNumber = try await getNextSequenceNumber(year: currentYear, companyId: companyId)
        
        // Format the ID
        let formattedSequence = String(format: "%0\(Self.sequenceLength)d", sequenceNumber)
        let quoteID = "\(Self.idPrefix)-\(currentYear)-\(formattedSequence)"
        
        // Verify uniqueness (extra safety check)
        if try await isQuoteIDTaken(quoteID, companyId: companyId) {
            // If somehow taken, recursively try the next number
            return try await generateUniqueQuoteID(companyId: companyId)
        }
        
        print("✅ Generated unique Quote ID: \(quoteID)")
        return quoteID
    }
    
    /// Validate that a Quote ID follows the correct format
    static func isValidQuoteID(_ id: String) -> Bool {
        let pattern = "^Q-\\d{4}-\\d{6}$"
        return id.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// Extract the year from a Quote ID
    static func getYearFromQuoteID(_ id: String) -> Int? {
        let components = id.components(separatedBy: "-")
        guard components.count == 3,
              components[0] == idPrefix,
              let year = Int(components[1]) else {
            return nil
        }
        return year
    }
    
    /// Extract the sequence number from a Quote ID
    static func getSequenceFromQuoteID(_ id: String) -> Int? {
        let components = id.components(separatedBy: "-")
        guard components.count == 3,
              components[0] == idPrefix,
              let sequence = Int(components[2]) else {
            return nil
        }
        return sequence
    }
    
    // MARK: - Private Methods
    
    private func getNextSequenceNumber(year: Int, companyId: String) async throws -> Int {
        // Find all quotes for this company and year
        let yearPrefix = "\(Self.idPrefix)-\(year)-"
        let predicate = NSPredicate(format: "companyId == %@ AND id BEGINSWITH %@", companyId, yearPrefix)
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        
        let quotes = try await repository.query(Quote.self, predicate: predicate, sortDescriptors: [sortDescriptor])
        
        guard let latestQuote = quotes.first else {
            // No quotes for this year yet, start with 1
            return 1
        }
        
        // Extract sequence number from the latest quote ID
        if let latestSequence = Self.getSequenceFromQuoteID(latestQuote.id) {
            return latestSequence + 1
        } else {
            // Fallback if ID format is corrupted
            print("⚠️ Warning: Found quote with invalid ID format: \(latestQuote.id)")
            return quotes.count + 1
        }
    }
    
    private func isQuoteIDTaken(_ id: String, companyId: String) async throws -> Bool {
        let predicate = NSPredicate(format: "companyId == %@ AND id == %@", companyId, id)
        let quotes = try await repository.query(Quote.self, predicate: predicate, sortDescriptors: nil)
        return !quotes.isEmpty
    }
}

// MARK: - Convenience Extensions

extension QuoteIDGenerator {
    /// Get statistics about Quote IDs for a given year
    func getYearlyStatistics(year: Int, companyId: String) async throws -> QuoteIDStatistics {
        let yearPrefix = "\(Self.idPrefix)-\(year)-"
        let predicate = NSPredicate(format: "companyId == %@ AND id BEGINSWITH %@", companyId, yearPrefix)
        
        let quotes = try await repository.query(Quote.self, predicate: predicate, sortDescriptors: nil)
        
        let totalQuotes = quotes.count
        let latestSequence = quotes.compactMap { Self.getSequenceFromQuoteID($0.id) }.max() ?? 0
        
        return QuoteIDStatistics(
            year: year,
            totalQuotes: totalQuotes,
            latestSequence: latestSequence,
            nextSequence: latestSequence + 1
        )
    }
    
    /// Get statistics for the current year
    func getCurrentYearStatistics(companyId: String) async throws -> QuoteIDStatistics {
        let currentYear = Calendar.current.component(.year, from: Date())
        return try await getYearlyStatistics(year: currentYear, companyId: companyId)
    }
}

/// Statistics about Quote ID generation for a specific year
struct QuoteIDStatistics: Sendable {
    let year: Int
    let totalQuotes: Int
    let latestSequence: Int
    let nextSequence: Int
    
    /// Formatted display of the next Quote ID that would be generated
    var nextQuoteID: String {
        let formattedSequence = String(format: "%06d", nextSequence)
        return "Q-\(year)-\(formattedSequence)"
    }
}

// MARK: - Errors

enum QuoteIDGeneratorError: Error, LocalizedError {
    case invalidFormat
    case sequenceOverflow
    case repositoryError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Quote ID format is invalid"
        case .sequenceOverflow:
            return "Quote sequence number has exceeded maximum value"
        case .repositoryError(let error):
            return "Repository error: \(error.localizedDescription)"
        }
    }
}
