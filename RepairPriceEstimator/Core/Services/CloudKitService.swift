@preconcurrency import Foundation
import CloudKit

/// CloudKit implementation of the data repository
@MainActor
final class CloudKitService: ObservableObject, DataRepository {
    static let shared = CloudKitService()
    
    private let container: CKContainer
    private let privateDB: CKDatabase
    
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var isSyncing: Bool = false
    
    init(containerIdentifier: String = "iCloud.com.jewelryrepair.estimator") {
        // Initialize CloudKit container
        // Note: Container initialization itself doesn't throw, but using it will fail
        // if entitlements are missing - we handle that in refreshAccountStatus
        self.container = CKContainer(identifier: containerIdentifier)
        self.privateDB = container.privateCloudDatabase
        
        Task {
            await refreshAccountStatus()
        }
    }
    
    var isAvailable: Bool {
        get async {
            accountStatus == .available
        }
    }
    
    // MARK: - Account Management
    
    func refreshAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                self.accountStatus = status
            }
        } catch {
            print("❌ Failed to get CloudKit account status: \(error)")
            await MainActor.run {
                self.accountStatus = .couldNotDetermine
            }
        }
    }
    
    // MARK: - Repository Implementation
    
    func save<T: CloudKitMappable>(_ item: T) async throws -> T {
        guard await isAvailable else {
            throw RepositoryError.notSignedInToiCloud
        }
        
        await MainActor.run { self.isSyncing = true }
        defer { Task { @MainActor in self.isSyncing = false } }
        
        do {
            let record = item.toRecord()
            let savedRecord = try await privateDB.save(record)
            return try T(from: savedRecord)
        } catch let error as CKError {
            throw mapCloudKitError(error)
        } catch {
            throw RepositoryError.unknownError(error)
        }
    }
    
    func fetch<T: CloudKitMappable>(_ type: T.Type, id: String) async throws -> T? {
        guard await isAvailable else {
            throw RepositoryError.notSignedInToiCloud
        }
        
        do {
            let recordID = CKRecord.ID(recordName: id)
            let record = try await privateDB.record(for: recordID)
            return try T(from: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        } catch let error as CKError {
            throw mapCloudKitError(error)
        } catch {
            throw RepositoryError.unknownError(error)
        }
    }
    
    func query<T: CloudKitMappable>(_ type: T.Type, parameters: QueryParameters) async throws -> [T] {
        guard await isAvailable else {
            throw RepositoryError.notSignedInToiCloud
        }
        
        do {
            // CloudKit requires at least one queryable field in the predicate
            // If no predicate is provided, create one that matches all records using a queryable field
            var predicate = parameters.predicate
            if predicate == nil || predicate == NSPredicate(value: true) {
                // Use a type-specific queryable field to match all records
                predicate = defaultPredicateForRecordType(T.recordType)
            }
            
            let query = CKQuery(recordType: T.recordType, predicate: predicate!)
            // Only add sort descriptor if not provided - use safe fields that exist in schema
            if parameters.sortDescriptors == nil {
                switch T.recordType {
                case "User":
                    query.sortDescriptors = [NSSortDescriptor(key: "email", ascending: true)]
                case "Company":
                    query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                case "Store":
                    query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                case "Guest":
                    query.sortDescriptors = [NSSortDescriptor(key: "lastName", ascending: true)]
                case "Quote":
                    query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                default:
                    // Don't set sort descriptor for types where createdAt might not exist
                    query.sortDescriptors = nil
                }
            } else {
                query.sortDescriptors = parameters.sortDescriptors
            }
            
            let (matchResults, _) = try await privateDB.records(matching: query)
            
            var items: [T] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    do {
                        let item = try T(from: record)
                        items.append(item)
                    } catch {
                        print("❌ Failed to decode record: \(error)")
                    }
                case .failure(let error):
                    print("❌ Failed to fetch record: \(error)")
                }
            }
            
            return items
        } catch let error as CKError {
            throw mapCloudKitError(error)
        } catch {
            throw RepositoryError.unknownError(error)
        }
    }
    
    func delete<T: CloudKitMappable>(_ type: T.Type, id: String) async throws {
        guard await isAvailable else {
            throw RepositoryError.notSignedInToiCloud
        }
        
        do {
            let recordID = CKRecord.ID(recordName: id)
            _ = try await privateDB.deleteRecord(withID: recordID)
        } catch let error as CKError {
            throw mapCloudKitError(error)
        } catch {
            throw RepositoryError.unknownError(error)
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Fetch all records for a company
    func fetchForCompany<T: CloudKitMappable>(_ type: T.Type, companyId: String) async throws -> [T] {
        let predicate = NSPredicate(format: "companyId == %@", companyId)
        return try await query(type, predicate: predicate, sortDescriptors: nil)
    }
    
    /// Fetch all active records for a company
    func fetchActiveForCompany<T: CloudKitMappable>(_ type: T.Type, companyId: String) async throws -> [T] {
        let predicate = NSPredicate(format: "companyId == %@ AND isActive == 1", companyId)
        return try await query(type, predicate: predicate, sortDescriptors: nil)
    }
    
    // MARK: - Helper Methods
    
    /// Returns a default predicate for a record type that uses a queryable field to match all records
    private func defaultPredicateForRecordType(_ recordType: String) -> NSPredicate {
        switch recordType {
        case "User":
            // User has email as queryable, use a pattern that matches all records
            return NSPredicate(format: "email != %@", "")
        case "Company":
            // Use name field which is always queryable
            return NSPredicate(format: "name != %@", "")
        case "Store":
            return NSPredicate(format: "name != %@", "") // Always true if stores exist
        case "Guest":
            return NSPredicate(format: "companyId != %@", "") // All guests have companyId
        case "Quote":
            return NSPredicate(format: "createdAt >= %@", Date.distantPast as NSDate)
        case "QuoteLineItem":
            return NSPredicate(format: "quoteId != %@", "") // All line items have quoteId
        case "ServiceType":
            return NSPredicate(format: "name != %@", "") // Always true if service types exist
        case "PricingRule":
            return NSPredicate(format: "name != %@", "") // Always true if rules exist
        case "MetalMarketRate":
            return NSPredicate(format: "metalType != %@", "") // Always true if rates exist
        case "LaborRate":
            return NSPredicate(format: "role != %@", "") // Always true if rates exist
        case "QuotePhoto":
            return NSPredicate(format: "quoteId != %@", "") // All photos have quoteId
        case "IntakeChecklist":
            return NSPredicate(format: "quoteId != %@", "") // All checklists have quoteId
        case "CommunicationLog":
            return NSPredicate(format: "createdAt >= %@", Date.distantPast as NSDate)
        case "CommunicationTemplate":
            return NSPredicate(format: "name != %@", "") // Always true if templates exist
        case "Vendor":
            return NSPredicate(format: "name != %@", "") // Always true if vendors exist
        case "VendorWorkOrder":
            return NSPredicate(format: "status != %@", "") // All work orders have status
        case "LooseDiamondDocumentation":
            return NSPredicate(format: "quoteId != %@", "") // All docs have quoteId
        case "AppraisalService":
            return NSPredicate(format: "createdAt >= %@", Date.distantPast as NSDate)
        case "StatusChangeLog":
            return NSPredicate(format: "entityType != %@", "") // All logs have entityType
        default:
            // Fallback: try to use createdAt if available, otherwise use any queryable string field
            return NSPredicate(format: "createdAt >= %@", Date.distantPast as NSDate)
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapCloudKitError(_ error: CKError) -> RepositoryError {
        switch error.code {
        case .notAuthenticated:
            return .notSignedInToiCloud
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .unknownItem:
            return .recordNotFound
        case .quotaExceeded:
            return .quotaExceeded
        case .permissionFailure:
            return .permissionFailure
        default:
            return .unknownError(error)
        }
    }
}
