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
        // Only save createdAt if it exists in the schema (will be added after schema update)
        // For now, CloudKit will use creationDate automatically
        // record["createdAt"] = createdAt as NSDate
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
        
        let createdAt = (record["createdAt"] as? Date) ?? record.creationDate ?? Date()
        
        self.init(
            id: record.recordID.recordName,
            companyId: companyId,
            storeIds: storeIds,
            role: role,
            displayName: displayName,
            email: email,
            isActive: isActive,
            createdAt: createdAt
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
        
        // Springer's specific fields
        record["springersItem"] = springersItem as NSNumber
        if let salesSku = salesSku { record["salesSku"] = salesSku as NSString }
        if let rushType = rushType { record["rushType"] = rushType.rawValue as NSString }
        if let requestedDueDate = requestedDueDate { record["requestedDueDate"] = requestedDueDate as NSDate }
        if let promisedDueDate = promisedDueDate { record["promisedDueDate"] = promisedDueDate as NSDate }
        record["coordinatorApprovalRequired"] = coordinatorApprovalRequired as NSNumber
        record["coordinatorApprovalGranted"] = coordinatorApprovalGranted as NSNumber
        if let intakeChecklistId = intakeChecklistId { record["intakeChecklistId"] = intakeChecklistId as NSString }
        record["primaryServiceCategory"] = primaryServiceCategory.rawValue as NSString
        record["priority"] = priority.rawValue as NSString
        record["estimateApproved"] = estimateApproved as NSNumber
        if let preApprovedLimit = preApprovedLimit { record["preApprovedLimit"] = preApprovedLimit as NSDecimalNumber }
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
        
        // Decode Springer's specific fields
        let rushType: RushType? = {
            if let rushTypeString = record["rushType"] as? String {
                return RushType(rawValue: rushTypeString)
            }
            return nil
        }()
        
        let primaryServiceCategory: ServiceCategory = {
            if let categoryString = record["primaryServiceCategory"] as? String,
               let category = ServiceCategory(rawValue: categoryString) {
                return category
            }
            return .jewelryRepair // Default
        }()
        
        let priority: QuotePriority = {
            if let priorityString = record["priority"] as? String,
               let priority = QuotePriority(rawValue: priorityString) {
                return priority
            }
            return .medium // Default
        }()
        
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
            customerFacingNotes: record["customerFacingNotes"] as? String,
            springersItem: (record["springersItem"] as? Bool) ?? false,
            salesSku: record["salesSku"] as? String,
            rushType: rushType,
            requestedDueDate: record["requestedDueDate"] as? Date,
            promisedDueDate: record["promisedDueDate"] as? Date,
            coordinatorApprovalRequired: (record["coordinatorApprovalRequired"] as? Bool) ?? false,
            coordinatorApprovalGranted: (record["coordinatorApprovalGranted"] as? Bool) ?? false,
            intakeChecklistId: record["intakeChecklistId"] as? String,
            primaryServiceCategory: primaryServiceCategory,
            priority: priority,
            estimateApproved: (record["estimateApproved"] as? Bool) ?? false,
            preApprovedLimit: (record["preApprovedLimit"] as? NSDecimalNumber)?.decimalValue
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
        
        // Springer's specific fields
        record["isGenericSku"] = isGenericSku as NSNumber
        record["requiresSpringersCheck"] = requiresSpringersCheck as NSNumber
        record["metalTypes"] = metalTypes.map { $0.rawValue } as NSArray
        if let sizingCategory = sizingCategory { record["sizingCategory"] = sizingCategory.rawValue as NSString }
        if let watchBrand = watchBrand { record["watchBrand"] = watchBrand as NSString }
        record["estimateRequired"] = estimateRequired as NSNumber
        record["vendorService"] = vendorService as NSNumber
        record["qualityControlRequired"] = qualityControlRequired as NSNumber
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
        
        // Decode Springer's specific fields
        let metalTypes: [MetalType] = (record["metalTypes"] as? [String])?.compactMap { MetalType(rawValue: $0) } ?? []
        let sizingCategory: SizingCategory? = {
            if let sizingString = record["sizingCategory"] as? String {
                return SizingCategory(rawValue: sizingString)
            }
            return nil
        }()
        
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
            isActive: isActive,
            isGenericSku: (record["isGenericSku"] as? Bool) ?? false,
            requiresSpringersCheck: (record["requiresSpringersCheck"] as? Bool) ?? false,
            metalTypes: metalTypes,
            sizingCategory: sizingCategory,
            watchBrand: record["watchBrand"] as? String,
            estimateRequired: (record["estimateRequired"] as? Bool) ?? false,
            vendorService: (record["vendorService"] as? Bool) ?? false,
            qualityControlRequired: (record["qualityControlRequired"] as? Bool) ?? true
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

// MARK: - IntakeChecklist
extension IntakeChecklist: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["quoteId"] = quoteId as NSString
        record["inspectorId"] = inspectorId as NSString
        record["inspectionDate"] = inspectionDate as NSDate
        
        // Encode findings as JSON
        if let findingsData = try? JSONEncoder().encode(findings),
           let findingsString = String(data: findingsData, encoding: .utf8) {
            record["findings"] = findingsString as NSString
        }
        
        record["overallCondition"] = overallCondition.rawValue as NSString
        record["safeToClean"] = safeToClean as NSNumber
        record["isRush"] = isRush as NSNumber
        if let salespersonId = salespersonId { record["salespersonId"] = salespersonId as NSString }
        record["repairType"] = repairType.rawValue as NSString
        record["photosRequired"] = photosRequired as NSNumber
        record["photosCaptured"] = photosCaptured as NSNumber
        record["shortDescription"] = shortDescription as NSString
        record["extendedDescription"] = extendedDescription as NSString
        record["conditionNotes"] = conditionNotes as NSString
        record["estimateRequired"] = estimateRequired as NSNumber
        if let preApprovedLimit = preApprovedLimit { record["preApprovedLimit"] = preApprovedLimit as NSDecimalNumber }
        record["requiresApproval"] = requiresApproval as NSNumber
        record["shippingDepositTaken"] = shippingDepositTaken as NSNumber
        if let shippingDepositAmount = shippingDepositAmount { record["shippingDepositAmount"] = shippingDepositAmount as NSDecimalNumber }
        if let specialHandling = specialHandling { record["specialHandling"] = specialHandling as NSString }
        if let requestedDueDate = requestedDueDate { record["requestedDueDate"] = requestedDueDate as NSDate }
        if let promisedDueDate = promisedDueDate { record["promisedDueDate"] = promisedDueDate as NSDate }
        record["dueDateRealistic"] = dueDateRealistic as NSNumber
        record["springersItem"] = springersItem as NSNumber
        record["highValue"] = highValue as NSNumber
        record["insuranceRequired"] = insuranceRequired as NSNumber
        record["customerPresent"] = customerPresent as NSNumber
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let quoteId = record["quoteId"] as? String,
              let inspectorId = record["inspectorId"] as? String,
              let inspectionDate = record["inspectionDate"] as? Date,
              let overallConditionString = record["overallCondition"] as? String,
              let overallCondition = ConditionSeverity(rawValue: overallConditionString),
              let safeToClean = record["safeToClean"] as? Bool,
              let isRush = record["isRush"] as? Bool,
              let repairTypeString = record["repairType"] as? String,
              let repairType = ServiceCategory(rawValue: repairTypeString),
              let photosRequired = record["photosRequired"] as? Bool,
              let photosCaptured = record["photosCaptured"] as? Int,
              let shortDescription = record["shortDescription"] as? String,
              let extendedDescription = record["extendedDescription"] as? String,
              let conditionNotes = record["conditionNotes"] as? String,
              let estimateRequired = record["estimateRequired"] as? Bool,
              let requiresApproval = record["requiresApproval"] as? Bool,
              let shippingDepositTaken = record["shippingDepositTaken"] as? Bool,
              let dueDateRealistic = record["dueDateRealistic"] as? Bool,
              let springersItem = record["springersItem"] as? Bool,
              let highValue = record["highValue"] as? Bool,
              let insuranceRequired = record["insuranceRequired"] as? Bool,
              let customerPresent = record["customerPresent"] as? Bool else {
            throw RepositoryError.invalidRecordData
        }
        
        // Decode findings from JSON
        var findings: [ConditionFinding] = []
        if let findingsString = record["findings"] as? String,
           let findingsData = findingsString.data(using: .utf8) {
            findings = (try? JSONDecoder().decode([ConditionFinding].self, from: findingsData)) ?? []
        }
        
        self.init(
            id: record.recordID.recordName,
            quoteId: quoteId,
            inspectorId: inspectorId,
            inspectionDate: inspectionDate,
            findings: findings,
            overallCondition: overallCondition,
            safeToClean: safeToClean,
            isRush: isRush,
            salespersonId: record["salespersonId"] as? String,
            repairType: repairType,
            photosRequired: photosRequired,
            photosCaptured: photosCaptured,
            shortDescription: shortDescription,
            extendedDescription: extendedDescription,
            conditionNotes: conditionNotes,
            estimateRequired: estimateRequired,
            preApprovedLimit: (record["preApprovedLimit"] as? NSDecimalNumber)?.decimalValue,
            requiresApproval: requiresApproval,
            shippingDepositTaken: shippingDepositTaken,
            shippingDepositAmount: (record["shippingDepositAmount"] as? NSDecimalNumber)?.decimalValue,
            specialHandling: record["specialHandling"] as? String,
            requestedDueDate: record["requestedDueDate"] as? Date,
            promisedDueDate: record["promisedDueDate"] as? Date,
            dueDateRealistic: dueDateRealistic,
            springersItem: springersItem,
            highValue: highValue,
            insuranceRequired: insuranceRequired,
            customerPresent: customerPresent
        )
    }
}

// MARK: - CommunicationLog
extension CommunicationLog: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["quoteId"] = quoteId as NSString
        record["guestId"] = guestId as NSString
        record["userId"] = userId as NSString
        record["type"] = type.rawValue as NSString
        record["direction"] = direction.rawValue as NSString
        record["purpose"] = purpose.rawValue as NSString
        record["status"] = status.rawValue as NSString
        if let subject = subject { record["subject"] = subject as NSString }
        record["message"] = message as NSString
        if let clientFacingNotes = clientFacingNotes { record["clientFacingNotes"] = clientFacingNotes as NSString }
        if let internalNotes = internalNotes { record["internalNotes"] = internalNotes as NSString }
        record["createdAt"] = createdAt as NSDate
        if let scheduledFor = scheduledFor { record["scheduledFor"] = scheduledFor as NSDate }
        if let completedAt = completedAt { record["completedAt"] = completedAt as NSDate }
        record["followUpRequired"] = followUpRequired as NSNumber
        if let followUpDate = followUpDate { record["followUpDate"] = followUpDate as NSDate }
        record["attachments"] = attachments as NSArray
        if let relatedStatus = relatedQuoteStatus { record["relatedQuoteStatus"] = relatedStatus.rawValue as NSString }
        record["automatedMessage"] = automatedMessage as NSNumber
        if let templateUsed = templateUsed { record["templateUsed"] = templateUsed as NSString }
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let quoteId = record["quoteId"] as? String,
              let guestId = record["guestId"] as? String,
              let userId = record["userId"] as? String,
              let typeString = record["type"] as? String,
              let type = CommunicationType(rawValue: typeString),
              let directionString = record["direction"] as? String,
              let direction = CommunicationDirection(rawValue: directionString),
              let purposeString = record["purpose"] as? String,
              let purpose = CommunicationPurpose(rawValue: purposeString),
              let statusString = record["status"] as? String,
              let status = CommunicationStatus(rawValue: statusString),
              let message = record["message"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let followUpRequired = record["followUpRequired"] as? Bool,
              let attachments = record["attachments"] as? [String],
              let automatedMessage = record["automatedMessage"] as? Bool else {
            throw RepositoryError.invalidRecordData
        }
        
        let relatedStatus: QuoteStatus? = {
            if let statusString = record["relatedQuoteStatus"] as? String {
                return QuoteStatus(rawValue: statusString)
            }
            return nil
        }()
        
        self.init(
            id: record.recordID.recordName,
            quoteId: quoteId,
            guestId: guestId,
            userId: userId,
            type: type,
            direction: direction,
            purpose: purpose,
            status: status,
            subject: record["subject"] as? String,
            message: message,
            clientFacingNotes: record["clientFacingNotes"] as? String,
            internalNotes: record["internalNotes"] as? String,
            createdAt: createdAt,
            scheduledFor: record["scheduledFor"] as? Date,
            completedAt: record["completedAt"] as? Date,
            followUpRequired: followUpRequired,
            followUpDate: record["followUpDate"] as? Date,
            attachments: attachments,
            relatedQuoteStatus: relatedStatus,
            automatedMessage: automatedMessage,
            templateUsed: record["templateUsed"] as? String
        )
    }
}

// MARK: - Vendor
extension Vendor: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["companyId"] = companyId as NSString
        record["name"] = name as NSString
        if let businessName = businessName { record["businessName"] = businessName as NSString }
        if let contactPerson = contactPerson { record["contactPerson"] = contactPerson as NSString }
        if let phone = phone { record["phone"] = phone as NSString }
        if let email = email { record["email"] = email as NSString }
        if let address = address { record["address"] = address as NSString }
        if let website = website { record["website"] = website as NSString }
        
        // Encode arrays
        record["serviceTypes"] = serviceTypes.map { $0.rawValue } as NSArray
        record["specializations"] = specializations.map { $0.rawValue } as NSArray
        record["supportedBrands"] = supportedBrands as NSArray
        
        record["typicalTurnaroundDays"] = typicalTurnaroundDays as NSNumber
        record["rushAvailable"] = rushAvailable as NSNumber
        if let rushTurnaroundDays = rushTurnaroundDays { record["rushTurnaroundDays"] = rushTurnaroundDays as NSNumber }
        if let minimumOrder = minimumOrder { record["minimumOrder"] = minimumOrder as NSDecimalNumber }
        if let paymentTerms = paymentTerms { record["paymentTerms"] = paymentTerms as NSString }
        if let shippingPolicy = shippingPolicy { record["shippingPolicy"] = shippingPolicy as NSString }
        record["qualityRating"] = qualityRating as NSDecimalNumber
        record["reliabilityRating"] = reliabilityRating as NSDecimalNumber
        record["communicationRating"] = communicationRating as NSDecimalNumber
        record["preferredVendor"] = preferredVendor as NSNumber
        record["isActive"] = isActive as NSNumber
        if let notes = notes { record["notes"] = notes as NSString }
        if let lastUsedDate = lastUsedDate { record["lastUsedDate"] = lastUsedDate as NSDate }
        record["createdAt"] = createdAt as NSDate
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let companyId = record["companyId"] as? String,
              let name = record["name"] as? String,
              let typicalTurnaroundDays = record["typicalTurnaroundDays"] as? Int,
              let rushAvailable = record["rushAvailable"] as? Bool,
              let qualityRating = record["qualityRating"] as? NSDecimalNumber,
              let reliabilityRating = record["reliabilityRating"] as? NSDecimalNumber,
              let communicationRating = record["communicationRating"] as? NSDecimalNumber,
              let preferredVendor = record["preferredVendor"] as? Bool,
              let isActive = record["isActive"] as? Bool,
              let createdAt = record["createdAt"] as? Date else {
            throw RepositoryError.invalidRecordData
        }
        
        // Decode arrays
        let serviceTypes: [VendorServiceType] = (record["serviceTypes"] as? [String])?.compactMap { VendorServiceType(rawValue: $0) } ?? []
        let specializations: [VendorSpecialization] = (record["specializations"] as? [String])?.compactMap { VendorSpecialization(rawValue: $0) } ?? []
        let supportedBrands: [String] = record["supportedBrands"] as? [String] ?? []
        
        self.init(
            id: record.recordID.recordName,
            companyId: companyId,
            name: name,
            businessName: record["businessName"] as? String,
            contactPerson: record["contactPerson"] as? String,
            phone: record["phone"] as? String,
            email: record["email"] as? String,
            address: record["address"] as? String,
            website: record["website"] as? String,
            serviceTypes: serviceTypes,
            specializations: specializations,
            supportedBrands: supportedBrands,
            typicalTurnaroundDays: typicalTurnaroundDays,
            rushAvailable: rushAvailable,
            rushTurnaroundDays: record["rushTurnaroundDays"] as? Int,
            minimumOrder: (record["minimumOrder"] as? NSDecimalNumber)?.decimalValue,
            paymentTerms: record["paymentTerms"] as? String,
            shippingPolicy: record["shippingPolicy"] as? String,
            qualityRating: qualityRating.decimalValue,
            reliabilityRating: reliabilityRating.decimalValue,
            communicationRating: communicationRating.decimalValue,
            preferredVendor: preferredVendor,
            isActive: isActive,
            notes: record["notes"] as? String,
            lastUsedDate: record["lastUsedDate"] as? Date,
            createdAt: createdAt
        )
    }
}

// MARK: - LooseDiamondDocumentation
extension LooseDiamondDocumentation: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["quoteId"] = quoteId as NSString
        if let lineItemId = lineItemId { record["lineItemId"] = lineItemId as NSString }
        record["documentedBy"] = documentedBy as NSString
        record["documentedAt"] = documentedAt as NSDate
        record["shape"] = shape.rawValue as NSString
        record["caratWeight"] = caratWeight as NSDecimalNumber
        if let color = color { record["color"] = color.rawValue as NSString }
        if let clarity = clarity { record["clarity"] = clarity.rawValue as NSString }
        record["origin"] = origin.rawValue as NSString
        if let lengthMM = lengthMM { record["lengthMM"] = lengthMM as NSDecimalNumber }
        if let widthMM = widthMM { record["widthMM"] = widthMM as NSDecimalNumber }
        if let depthMM = depthMM { record["depthMM"] = depthMM as NSDecimalNumber }
        if let tablePercentage = tablePercentage { record["tablePercentage"] = tablePercentage as NSDecimalNumber }
        if let depthPercentage = depthPercentage { record["depthPercentage"] = depthPercentage as NSDecimalNumber }
        if let laserInscription = laserInscription { record["laserInscription"] = laserInscription as NSString }
        if let certificationNumber = certificationNumber { record["certificationNumber"] = certificationNumber as NSString }
        if let certificationLab = certificationLab { record["certificationLab"] = certificationLab as NSString }
        if let girdleDescription = girdleDescription { record["girdleDescription"] = girdleDescription as NSString }
        if let fluorescence = fluorescence { record["fluorescence"] = fluorescence as NSString }
        if let estimatedValue = estimatedValue { record["estimatedValue"] = estimatedValue as NSDecimalNumber }
        if let replacementValue = replacementValue { record["replacementValue"] = replacementValue as NSDecimalNumber }
        record["appraisalRequired"] = appraisalRequired as NSNumber
        record["weightVerified"] = weightVerified as NSNumber
        record["measurementsVerified"] = measurementsVerified as NSNumber
        record["inscriptionVerified"] = inscriptionVerified as NSNumber
        if let verificationNotes = verificationNotes { record["verificationNotes"] = verificationNotes as NSString }
        record["photoIds"] = photoIds as NSArray
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let quoteId = record["quoteId"] as? String,
              let documentedBy = record["documentedBy"] as? String,
              let documentedAt = record["documentedAt"] as? Date,
              let shapeString = record["shape"] as? String,
              let shape = DiamondShape(rawValue: shapeString),
              let caratWeight = record["caratWeight"] as? NSDecimalNumber,
              let originString = record["origin"] as? String,
              let origin = DiamondOrigin(rawValue: originString),
              let appraisalRequired = record["appraisalRequired"] as? Bool,
              let weightVerified = record["weightVerified"] as? Bool,
              let measurementsVerified = record["measurementsVerified"] as? Bool,
              let inscriptionVerified = record["inscriptionVerified"] as? Bool,
              let photoIds = record["photoIds"] as? [String] else {
            throw RepositoryError.invalidRecordData
        }
        
        let color: DiamondColor? = {
            if let colorString = record["color"] as? String {
                return DiamondColor(rawValue: colorString)
            }
            return nil
        }()
        
        let clarity: DiamondClarity? = {
            if let clarityString = record["clarity"] as? String {
                return DiamondClarity(rawValue: clarityString)
            }
            return nil
        }()
        
        self.init(
            id: record.recordID.recordName,
            quoteId: quoteId,
            lineItemId: record["lineItemId"] as? String,
            documentedBy: documentedBy,
            documentedAt: documentedAt,
            shape: shape,
            caratWeight: caratWeight.decimalValue,
            color: color,
            clarity: clarity,
            origin: origin,
            lengthMM: (record["lengthMM"] as? NSDecimalNumber)?.decimalValue,
            widthMM: (record["widthMM"] as? NSDecimalNumber)?.decimalValue,
            depthMM: (record["depthMM"] as? NSDecimalNumber)?.decimalValue,
            tablePercentage: (record["tablePercentage"] as? NSDecimalNumber)?.decimalValue,
            depthPercentage: (record["depthPercentage"] as? NSDecimalNumber)?.decimalValue,
            laserInscription: record["laserInscription"] as? String,
            certificationNumber: record["certificationNumber"] as? String,
            certificationLab: record["certificationLab"] as? String,
            girdleDescription: record["girdleDescription"] as? String,
            fluorescence: record["fluorescence"] as? String,
            estimatedValue: (record["estimatedValue"] as? NSDecimalNumber)?.decimalValue,
            replacementValue: (record["replacementValue"] as? NSDecimalNumber)?.decimalValue,
            appraisalRequired: appraisalRequired,
            weightVerified: weightVerified,
            measurementsVerified: measurementsVerified,
            inscriptionVerified: inscriptionVerified,
            verificationNotes: record["verificationNotes"] as? String,
            photoIds: photoIds
        )
    }
}

// MARK: - AppraisalService
extension AppraisalService: CloudKitMappable {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["quoteId"] = quoteId as NSString
        record["guestId"] = guestId as NSString
        record["appraiserId"] = appraiserId as NSString
        record["appraisalType"] = appraisalType.rawValue as NSString
        record["pricingTier"] = pricingTier.rawValue as NSString
        record["itemCount"] = itemCount as NSNumber
        record["largestCaratWeight"] = largestCaratWeight as NSDecimalNumber
        record["calculatedFee"] = calculatedFee as NSDecimalNumber
        record["finalFee"] = finalFee as NSDecimalNumber
        if let feeOverrideReason = feeOverrideReason { record["feeOverrideReason"] = feeOverrideReason as NSString }
        record["createdAt"] = createdAt as NSDate
        if let scheduledDate = scheduledDate { record["scheduledDate"] = scheduledDate as NSDate }
        if let completedDate = completedDate { record["completedDate"] = completedDate as NSDate }
        record["expedited"] = expedited as NSNumber
        record["expediteMultiplier"] = expediteMultiplier as NSDecimalNumber
        record["sarinReportRequested"] = sarinReportRequested as NSNumber
        record["gemIdRequested"] = gemIdRequested as NSNumber
        record["photoDocumentation"] = photoDocumentation as NSNumber
        record["certificationVerification"] = certificationVerification as NSNumber
        record["isUpdate"] = isUpdate as NSNumber
        if let originalAppraisalDate = originalAppraisalDate { record["originalAppraisalDate"] = originalAppraisalDate as NSDate }
        if let updateDiscount = updateDiscount { record["updateDiscount"] = updateDiscount as NSDecimalNumber }
        record["status"] = status.rawValue as NSString
        record["deliveryMethod"] = deliveryMethod.rawValue as NSString
        if let notes = notes { record["notes"] = notes as NSString }
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let quoteId = record["quoteId"] as? String,
              let guestId = record["guestId"] as? String,
              let appraiserId = record["appraiserId"] as? String,
              let appraisalTypeString = record["appraisalType"] as? String,
              let appraisalType = AppraisalType(rawValue: appraisalTypeString),
              let pricingTierString = record["pricingTier"] as? String,
              let pricingTier = AppraisalPricingTier(rawValue: pricingTierString),
              let itemCount = record["itemCount"] as? Int,
              let largestCaratWeight = record["largestCaratWeight"] as? NSDecimalNumber,
              let calculatedFee = record["calculatedFee"] as? NSDecimalNumber,
              let finalFee = record["finalFee"] as? NSDecimalNumber,
              let expedited = record["expedited"] as? Bool,
              let expediteMultiplier = record["expediteMultiplier"] as? NSDecimalNumber,
              let sarinReportRequested = record["sarinReportRequested"] as? Bool,
              let gemIdRequested = record["gemIdRequested"] as? Bool,
              let photoDocumentation = record["photoDocumentation"] as? Bool,
              let certificationVerification = record["certificationVerification"] as? Bool,
              let isUpdate = record["isUpdate"] as? Bool,
              let statusString = record["status"] as? String,
              let status = AppraisalStatus(rawValue: statusString),
              let deliveryMethodString = record["deliveryMethod"] as? String,
              let deliveryMethod = AppraisalDeliveryMethod(rawValue: deliveryMethodString),
              let createdAt = record["createdAt"] as? Date else {
            throw RepositoryError.invalidRecordData
        }
        
        self.init(
            id: record.recordID.recordName,
            quoteId: quoteId,
            guestId: guestId,
            appraiserId: appraiserId,
            appraisalType: appraisalType,
            pricingTier: pricingTier,
            itemCount: itemCount,
            largestCaratWeight: largestCaratWeight.decimalValue,
            calculatedFee: calculatedFee.decimalValue,
            finalFee: finalFee.decimalValue,
            feeOverrideReason: record["feeOverrideReason"] as? String,
            createdAt: createdAt,
            scheduledDate: record["scheduledDate"] as? Date,
            completedDate: record["completedDate"] as? Date,
            expedited: expedited,
            expediteMultiplier: expediteMultiplier.decimalValue,
            sarinReportRequested: sarinReportRequested,
            gemIdRequested: gemIdRequested,
            photoDocumentation: photoDocumentation,
            certificationVerification: certificationVerification,
            isUpdate: isUpdate,
            originalAppraisalDate: record["originalAppraisalDate"] as? Date,
            updateDiscount: (record["updateDiscount"] as? NSDecimalNumber)?.decimalValue,
            status: status,
            deliveryMethod: deliveryMethod,
            notes: record["notes"] as? String
        )
    }
}
