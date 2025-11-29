@preconcurrency import Foundation
import CloudKit

/// Sendable wrapper for query parameters to satisfy Swift 6 concurrency requirements
/// NSPredicate and NSSortDescriptor are effectively immutable and safe to pass across isolation boundaries
struct QueryParameters: @unchecked Sendable {
    let predicate: NSPredicate?
    let sortDescriptors: [NSSortDescriptor]?
    
    init(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
    }
}

/// Protocol for data repository operations, abstracted from CloudKit
protocol DataRepository {
    /// Save a record to the repository
    func save<T: CloudKitMappable>(_ item: T) async throws -> T
    
    /// Fetch a record by ID
    func fetch<T: CloudKitMappable>(_ type: T.Type, id: String) async throws -> T?
    
    /// Query records with predicate
    func query<T: CloudKitMappable>(_ type: T.Type, parameters: QueryParameters) async throws -> [T]
    
    /// Query records with predicate (convenience method with default implementation)
    func query<T: CloudKitMappable>(_ type: T.Type, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) async throws -> [T]
    
    /// Delete a record by ID
    func delete<T: CloudKitMappable>(_ type: T.Type, id: String) async throws
    
    /// Check if repository is available (user signed into iCloud)
    var isAvailable: Bool { get async }
}

/// Default implementation for convenience query method
extension DataRepository {
    func query<T: CloudKitMappable>(_ type: T.Type, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) async throws -> [T] {
        let parameters = QueryParameters(predicate: predicate, sortDescriptors: sortDescriptors)
        return try await query(type, parameters: parameters)
    }
}

/// Protocol for types that can be mapped to/from CloudKit records
protocol CloudKitMappable: Identifiable, Codable, Sendable {
    static var recordType: String { get }
    
    /// Convert the model to a CloudKit record
    func toRecord() -> CKRecord
    
    /// Initialize from a CloudKit record
    init(from record: CKRecord) throws
}

/// Errors that can occur during repository operations
enum RepositoryError: Error, LocalizedError {
    case notSignedInToiCloud
    case networkUnavailable
    case recordNotFound
    case invalidRecordData
    case quotaExceeded
    case permissionFailure
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notSignedInToiCloud:
            return "Please sign in to iCloud to sync data"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .recordNotFound:
            return "Record not found"
        case .invalidRecordData:
            return "Invalid record data"
        case .quotaExceeded:
            return "iCloud storage quota exceeded"
        case .permissionFailure:
            return "Permission denied"
        case .unknownError(let error):
            return error.localizedDescription
        }
    }
}
