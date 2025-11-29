import Foundation
import CloudKit

/// Represents a photo attached to a quote
struct QuotePhoto: Identifiable, Codable, Sendable {
    let id: String
    let quoteId: String
    let assetURL: URL? // Will store the CloudKit asset reference
    let caption: String?
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        quoteId: String,
        assetURL: URL? = nil,
        caption: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.quoteId = quoteId
        self.assetURL = assetURL
        self.caption = caption
        self.createdAt = createdAt
    }
    
    /// Whether the photo has been uploaded to CloudKit
    var isUploaded: Bool {
        assetURL != nil
    }
}

// MARK: - CloudKit Record Type
extension QuotePhoto {
    static let recordType = "QuotePhoto"
}
