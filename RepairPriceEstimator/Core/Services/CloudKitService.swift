import Foundation
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
    
    func query<T: CloudKitMappable>(_ type: T.Type, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) async throws -> [T] {
        guard await isAvailable else {
            throw RepositoryError.notSignedInToiCloud
        }
        
        do {
            let query = CKQuery(recordType: T.recordType, predicate: predicate ?? NSPredicate(value: true))
            query.sortDescriptors = sortDescriptors
            
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
        let predicate = NSPredicate(format: "companyId == %@ AND isActive == YES", companyId)
        return try await query(type, predicate: predicate, sortDescriptors: nil)
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
