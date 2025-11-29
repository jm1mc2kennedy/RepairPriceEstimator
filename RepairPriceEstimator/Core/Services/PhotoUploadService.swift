import Foundation
import CloudKit
import UIKit

/// Service for uploading photos to CloudKit as assets
@MainActor
final class PhotoUploadService {
    private let container: CKContainer
    private let privateDB: CKDatabase
    
    init(containerIdentifier: String = "iCloud.com.jewelryrepair.estimator") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.privateDB = container.privateCloudDatabase
    }
    
    /// Upload image data to CloudKit and return the QuotePhoto
    func uploadPhoto(imageData: Data, quoteId: String, caption: String? = nil) async throws -> QuotePhoto {
        // Create temporary file for the image
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        
        // Write image data to temporary file
        try imageData.write(to: tempURL)
        
        // Create CKAsset from file
        let asset = CKAsset(fileURL: tempURL)
        
        // Create QuotePhoto record
        let photoId = UUID().uuidString
        let record = CKRecord(recordType: QuotePhoto.recordType, recordID: CKRecord.ID(recordName: photoId))
        record["quoteId"] = quoteId as NSString
        record["assetReference"] = asset
        if let caption = caption {
            record["caption"] = caption as NSString
        }
        record["createdAt"] = Date() as NSDate
        
        // Upload record to CloudKit
        do {
            let savedRecord = try await privateDB.save(record)
            
            // Create QuotePhoto from saved record
            let photo = try QuotePhoto(from: savedRecord)
            
            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempURL)
            
            print("✅ Photo uploaded successfully: \(photo.id)")
            return photo
        } catch {
            // Clean up temporary file on error
            try? FileManager.default.removeItem(at: tempURL)
            print("❌ Error uploading photo: \(error)")
            throw error
        }
    }
    
    /// Upload multiple photos in batch
    func uploadPhotos(photos: [(imageData: Data, caption: String?)], quoteId: String) async throws -> [QuotePhoto] {
        var uploadedPhotos: [QuotePhoto] = []
        
        for (imageData, caption) in photos {
            let photo = try await uploadPhoto(imageData: imageData, quoteId: quoteId, caption: caption)
            uploadedPhotos.append(photo)
        }
        
        return uploadedPhotos
    }
}

