import Foundation
import CloudKit

// MARK: - CloudKitMappable Extensions

// MARK: - Company
extension Company: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["name"] = name as NSString
        record["primaryContactInfo"] = primaryContactInfo as NSString
        record["createdAt"] = createdAt as NSDate
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let name = record["name"] as? String,
              let primaryContactInfo = record["primaryContactInfo"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            throw RepositoryError.invalidRecordData
        }
        
        self.init(
            id: record.recordID.recordName,
            name: name,
            primaryContactInfo: primaryContactInfo,
            createdAt: createdAt
        )
    }
}

// MARK: - Store
extension Store: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["companyId"] = companyId as NSString
        record["name"] = name as NSString
        record["storeCode"] = storeCode as NSString
        record["location"] = location as NSString
        record["phone"] = phone as NSString
        record["isActive"] = isActive as NSNumber
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let companyId = record["companyId"] as? String,
              let name = record["name"] as? String,
              let storeCode = record["storeCode"] as? String,
              let location = record["location"] as? String,
              let phone = record["phone"] as? String,
              let isActive = record["isActive"] as? Bool else {
            throw RepositoryError.invalidRecordData
        }
        
        self.init(
            id: record.recordID.recordName,
            companyId: companyId,
            name: name,
            storeCode: storeCode,
            location: location,
            phone: phone,
            isActive: isActive
        )
    }
}

// MARK: - User
extension User: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["companyId"] = companyId as NSString
        record["storeIds"] = storeIds as NSArray
        record["role"] = role.rawValue as NSString
        record["displayName"] = displayName as NSString
        record["email"] = email as NSString
        record["isActive"] = isActive as NSNumber
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let companyId = record["companyId"] as? String,
              let storeIds = record["storeIds"] as? [String],
              let roleString = record["role"] as? String,
              let role = UserRole(rawValue: roleString),
              let displayName = record["displayName"] as? String,
              let email = record["email"] as? String,
              let isActive = record["isActive"] as? Bool else {
            throw RepositoryError.invalidRecordData
        }
        
        self.init(
            id: record.recordID.recordName,
            companyId: companyId,
            storeIds: storeIds,
            role: role,
            displayName: displayName,
            email: email,
            isActive: isActive
        )
    }
}

// MARK: - Guest
extension Guest: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["companyId"] = companyId as NSString
        record["primaryStoreId"] = primaryStoreId as NSString
        record["firstName"] = firstName as NSString
        record["lastName"] = lastName as NSString
        if let email = email { record["email"] = email as NSString }
        if let phone = phone { record["phone"] = phone as NSString }
        if let notes = notes { record["notes"] = notes as NSString }
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let companyId = record["companyId"] as? String,
              let primaryStoreId = record["primaryStoreId"] as? String,
              let firstName = record["firstName"] as? String,
              let lastName = record["lastName"] as? String else {
            throw RepositoryError.invalidRecordData
        }
        
        self.init(
            id: record.recordID.recordName,
            companyId: companyId,
            primaryStoreId: primaryStoreId,
            firstName: firstName,
            lastName: lastName,
            email: record["email"] as? String,
            phone: record["phone"] as? String,
            notes: record["notes"] as? String
        )
    }
}

// MARK: - Quote
extension Quote: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["companyId"] = companyId as NSString
        record["storeId"] = storeId as NSString
        record["guestId"] = guestId as NSString
        record["status"] = status.rawValue as NSString
        record["createdAt"] = createdAt as NSDate
        record["updatedAt"] = updatedAt as NSDate
        record["validUntil"] = validUntil as NSDate
        record["currencyCode"] = currencyCode as NSString
        record["subtotal"] = subtotal as NSDecimalNumber
        record["tax"] = tax as NSDecimalNumber
        record["total"] = total as NSDecimalNumber
        record["rushMultiplierApplied"] = rushMultiplierApplied as NSDecimalNumber
        record["pricingVersion"] = pricingVersion as NSString
        if let internalNotes = internalNotes { record["internalNotes"] = internalNotes as NSString }
        if let customerFacingNotes = customerFacingNotes { record["customerFacingNotes"] = customerFacingNotes as NSString }
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let companyId = record["companyId"] as? String,
              let storeId = record["storeId"] as? String,
              let guestId = record["guestId"] as? String,
              let statusString = record["status"] as? String,
              let status = QuoteStatus(rawValue: statusString),
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date,
              let validUntil = record["validUntil"] as? Date,
              let currencyCode = record["currencyCode"] as? String,
              let subtotal = record["subtotal"] as? NSDecimalNumber,
              let tax = record["tax"] as? NSDecimalNumber,
              let total = record["total"] as? NSDecimalNumber,
              let rushMultiplierApplied = record["rushMultiplierApplied"] as? NSDecimalNumber,
              let pricingVersion = record["pricingVersion"] as? String else {
            throw RepositoryError.invalidRecordData
        }
        
        self.init(
            id: record.recordID.recordName,
            companyId: companyId,
            storeId: storeId,
            guestId: guestId,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            validUntil: validUntil,
            currencyCode: currencyCode,
            subtotal: subtotal.decimalValue,
            tax: tax.decimalValue,
            total: total.decimalValue,
            rushMultiplierApplied: rushMultiplierApplied.decimalValue,
            pricingVersion: pricingVersion,
            internalNotes: record["internalNotes"] as? String,
            customerFacingNotes: record["customerFacingNotes"] as? String
        )
    }
}

// MARK: - QuoteLineItem
extension QuoteLineItem: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["quoteId"] = quoteId as NSString
        record["serviceTypeId"] = serviceTypeId as NSString
        record["sku"] = sku as NSString
        record["description"] = description as NSString
        if let metalType = metalType { record["metalType"] = metalType.rawValue as NSString }
        if let metalWeightGrams = metalWeightGrams { record["metalWeightGrams"] = metalWeightGrams as NSDecimalNumber }
        record["laborMinutes"] = laborMinutes as NSNumber
        record["baseCost"] = baseCost as NSDecimalNumber
        record["baseRetail"] = baseRetail as NSDecimalNumber
        record["calculatedRetail"] = calculatedRetail as NSDecimalNumber
        if let manualOverrideRetail = manualOverrideRetail { record["manualOverrideRetail"] = manualOverrideRetail as NSDecimalNumber }
        if let overrideReason = overrideReason { record["overrideReason"] = overrideReason as NSString }
        record["isRush"] = isRush as NSNumber
        record["rushMultiplier"] = rushMultiplier as NSDecimalNumber
        record["finalRetail"] = finalRetail as NSDecimalNumber
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let quoteId = record["quoteId"] as? String,
              let serviceTypeId = record["serviceTypeId"] as? String,
              let sku = record["sku"] as? String,
              let description = record["description"] as? String,
              let laborMinutes = record["laborMinutes"] as? Int,
              let baseCost = record["baseCost"] as? NSDecimalNumber,
              let baseRetail = record["baseRetail"] as? NSDecimalNumber,
              let calculatedRetail = record["calculatedRetail"] as? NSDecimalNumber,
              let isRush = record["isRush"] as? Bool,
              let rushMultiplier = record["rushMultiplier"] as? NSDecimalNumber,
              let finalRetail = record["finalRetail"] as? NSDecimalNumber else {
            throw RepositoryError.invalidRecordData
        }
        
        let metalType: MetalType? = {
            if let metalTypeString = record["metalType"] as? String {
                return MetalType(rawValue: metalTypeString)
            }
            return nil
        }()
        
        self.init(
            id: record.recordID.recordName,
            quoteId: quoteId,
            serviceTypeId: serviceTypeId,
            sku: sku,
            description: description,
            metalType: metalType,
            metalWeightGrams: (record["metalWeightGrams"] as? NSDecimalNumber)?.decimalValue,
            laborMinutes: laborMinutes,
            baseCost: baseCost.decimalValue,
            baseRetail: baseRetail.decimalValue,
            calculatedRetail: calculatedRetail.decimalValue,
            manualOverrideRetail: (record["manualOverrideRetail"] as? NSDecimalNumber)?.decimalValue,
            overrideReason: record["overrideReason"] as? String,
            isRush: isRush,
            rushMultiplier: rushMultiplier.decimalValue,
            finalRetail: finalRetail.decimalValue
        )
    }
}

// MARK: - ServiceType
extension ServiceType: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["companyId"] = companyId as NSString
        record["name"] = name as NSString
        record["category"] = category.rawValue as NSString
        record["defaultSku"] = defaultSku as NSString
        record["defaultLaborMinutes"] = defaultLaborMinutes as NSNumber
        if let defaultMetalUsageGrams = defaultMetalUsageGrams { record["defaultMetalUsageGrams"] = defaultMetalUsageGrams as NSDecimalNumber }
        record["baseRetail"] = baseRetail as NSDecimalNumber
        record["baseCost"] = baseCost as NSDecimalNumber
        if let pricingFormulaId = pricingFormulaId { record["pricingFormulaId"] = pricingFormulaId as NSString }
        record["isActive"] = isActive as NSNumber
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let companyId = record["companyId"] as? String,
              let name = record["name"] as? String,
              let categoryString = record["category"] as? String,
              let category = ServiceCategory(rawValue: categoryString),
              let defaultSku = record["defaultSku"] as? String,
              let defaultLaborMinutes = record["defaultLaborMinutes"] as? Int,
              let baseRetail = record["baseRetail"] as? NSDecimalNumber,
              let baseCost = record["baseCost"] as? NSDecimalNumber,
              let isActive = record["isActive"] as? Bool else {
            throw RepositoryError.invalidRecordData
        }
        
        self.init(
            id: record.recordID.recordName,
            companyId: companyId,
            name: name,
            category: category,
            defaultSku: defaultSku,
            defaultLaborMinutes: defaultLaborMinutes,
            defaultMetalUsageGrams: (record["defaultMetalUsageGrams"] as? NSDecimalNumber)?.decimalValue,
            baseRetail: baseRetail.decimalValue,
            baseCost: baseCost.decimalValue,
            pricingFormulaId: record["pricingFormulaId"] as? String,
            isActive: isActive
        )
    }
}

// MARK: - PricingRule
extension PricingRule: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["companyId"] = companyId as NSString
        record["name"] = name as NSString
        record["description"] = description as NSString
        
        // Encode formulaDefinition as JSON
        if let formulaData = try? JSONEncoder().encode(formulaDefinition),
           let formulaString = String(data: formulaData, encoding: .utf8) {
            record["formulaDefinition"] = formulaString as NSString
        }
        
        record["allowManualOverride"] = allowManualOverride as NSNumber
        if let requireManagerApprovalIfOverrideExceedsPercent = requireManagerApprovalIfOverrideExceedsPercent {
            record["requireManagerApprovalIfOverrideExceedsPercent"] = requireManagerApprovalIfOverrideExceedsPercent as NSDecimalNumber
        }
        record["isActive"] = isActive as NSNumber
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let companyId = record["companyId"] as? String,
              let name = record["name"] as? String,
              let description = record["description"] as? String,
              let formulaString = record["formulaDefinition"] as? String,
              let formulaData = formulaString.data(using: .utf8),
              let formulaDefinition = try? JSONDecoder().decode(PricingFormula.self, from: formulaData),
              let allowManualOverride = record["allowManualOverride"] as? Bool,
              let isActive = record["isActive"] as? Bool else {
            throw RepositoryError.invalidRecordData
        }
        
        self.init(
            id: record.recordID.recordName,
            companyId: companyId,
            name: name,
            description: description,
            formulaDefinition: formulaDefinition,
            allowManualOverride: allowManualOverride,
            requireManagerApprovalIfOverrideExceedsPercent: (record["requireManagerApprovalIfOverrideExceedsPercent"] as? NSDecimalNumber)?.decimalValue,
            isActive: isActive
        )
    }
}

// MARK: - MetalMarketRate
extension MetalMarketRate: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["companyId"] = companyId as NSString
        record["metalType"] = metalType.rawValue as NSString
        record["unit"] = unit.rawValue as NSString
        record["rate"] = rate as NSDecimalNumber
        record["effectiveDate"] = effectiveDate as NSDate
        record["createdAt"] = createdAt as NSDate
        record["isActive"] = isActive as NSNumber
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let companyId = record["companyId"] as? String,
              let metalTypeString = record["metalType"] as? String,
              let metalType = MetalType(rawValue: metalTypeString),
              let unitString = record["unit"] as? String,
              let unit = MetalUnit(rawValue: unitString),
              let rate = record["rate"] as? NSDecimalNumber,
              let effectiveDate = record["effectiveDate"] as? Date,
              let createdAt = record["createdAt"] as? Date,
              let isActive = record["isActive"] as? Bool else {
            throw RepositoryError.invalidRecordData
        }
        
        self.init(
            id: record.recordID.recordName,
            companyId: companyId,
            metalType: metalType,
            unit: unit,
            rate: rate.decimalValue,
            effectiveDate: effectiveDate,
            createdAt: createdAt,
            isActive: isActive
        )
    }
}

// MARK: - LaborRate
extension LaborRate: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["companyId"] = companyId as NSString
        record["role"] = role.rawValue as NSString
        record["ratePerHour"] = ratePerHour as NSDecimalNumber
        record["effectiveDate"] = effectiveDate as NSDate
        record["createdAt"] = createdAt as NSDate
        record["isActive"] = isActive as NSNumber
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let companyId = record["companyId"] as? String,
              let roleString = record["role"] as? String,
              let role = UserRole(rawValue: roleString),
              let ratePerHour = record["ratePerHour"] as? NSDecimalNumber,
              let effectiveDate = record["effectiveDate"] as? Date,
              let createdAt = record["createdAt"] as? Date,
              let isActive = record["isActive"] as? Bool else {
            throw RepositoryError.invalidRecordData
        }
        
        self.init(
            id: record.recordID.recordName,
            companyId: companyId,
            role: role,
            ratePerHour: ratePerHour.decimalValue,
            effectiveDate: effectiveDate,
            createdAt: createdAt,
            isActive: isActive
        )
    }
}

// MARK: - QuotePhoto
extension QuotePhoto: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["quoteId"] = quoteId as NSString
        if let assetURL = assetURL {
            record["assetReference"] = CKAsset(fileURL: assetURL)
        }
        if let caption = caption { record["caption"] = caption as NSString }
        record["createdAt"] = createdAt as NSDate
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let quoteId = record["quoteId"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            throw RepositoryError.invalidRecordData
        }
        
        let assetURL: URL? = (record["assetReference"] as? CKAsset)?.fileURL
        
        self.init(
            id: record.recordID.recordName,
            quoteId: quoteId,
            assetURL: assetURL,
            caption: record["caption"] as? String,
            createdAt: createdAt
        )
    }
}
