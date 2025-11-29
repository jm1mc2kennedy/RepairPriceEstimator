# CloudKit Schema Setup Guide

This guide will help you set up the CloudKit schema in your Apple Developer account so the app can properly store and retrieve data.

## Prerequisites

1. Apple Developer Account (free or paid)
2. CloudKit container: `iCloud.com.jewelryrepair.estimator`
3. Xcode with CloudKit capabilities configured

## Setup Steps

### 1. Access CloudKit Console

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Sign in with your Apple ID
3. Navigate to **Certificates, Identifiers & Profiles**
4. Click **Identifiers** → **CloudKit Containers**
5. Find or create container: `iCloud.com.jewelryrepair.estimator`
6. Click on the container → **CloudKit Console**

### 2. Schema Initialization

**Option A: Automatic Schema Creation (Recommended)**

The easiest way to create the schema is to let CloudKit create it automatically when you first run the app:

1. Make sure your app is properly code-signed with your developer team
2. Run the app in the simulator or on a device
3. The app will attempt to bootstrap data, which will create the schema automatically
4. Go to CloudKit Console → **Schema** → **Record Types** to verify

**Option B: Manual Schema Creation**

If automatic creation doesn't work, you can create the schema manually in CloudKit Console.

## Required Record Types

### Company
- `name` (String, Required)
- `primaryContactInfo` (String, Required)
- `createdAt` (Date/Time, Required)

### Store
- `companyId` (String, Required, Reference to Company)
- `name` (String, Required)
- `storeCode` (String, Required)
- `location` (String, Required)
- `phone` (String, Required)
- `isActive` (Int(64), Required)

### User
- `companyId` (String, Required, Reference to Company)
- `storeIds` (String List, Required)
- `role` (String, Required)
- `displayName` (String, Required)
- `email` (String, Required)
- `isActive` (Int(64), Required)

### Guest
- `companyId` (String, Required, Reference to Company)
- `storeId` (String, Required, Reference to Store)
- `firstName` (String, Required)
- `lastName` (String, Required)
- `email` (String, Optional)
- `phone` (String, Optional)
- `address` (String, Optional)
- `notes` (String, Optional)
- `createdAt` (Date/Time, Required)
- `lastQuoteDate` (Date/Time, Optional)

### Quote
- `companyId` (String, Required, Reference to Company)
- `storeId` (String, Required, Reference to Store)
- `guestId` (String, Required, Reference to Guest)
- `status` (String, Required)
- `createdAt` (Date/Time, Required)
- `updatedAt` (Date/Time, Required)
- `validUntil` (Date/Time, Required)
- `currencyCode` (String, Required)
- `subtotal` (Double, Required)
- `tax` (Double, Required)
- `total` (Double, Required)
- `rushMultiplierApplied` (Double, Required)
- `pricingVersion` (String, Required)
- `internalNotes` (String, Optional)
- `customerFacingNotes` (String, Optional)
- `springersItem` (Int(64), Required)
- `salesSku` (String, Optional)
- `rushType` (String, Optional)
- `requestedDueDate` (Date/Time, Optional)
- `promisedDueDate` (Date/Time, Optional)
- `coordinatorApprovalRequired` (Int(64), Required)
- `coordinatorApprovalGranted` (Int(64), Required)
- `intakeChecklistId` (String, Optional)
- `primaryServiceCategory` (String, Required)
- `priority` (String, Required)

### QuoteLineItem
- `quoteId` (String, Required, Reference to Quote)
- `serviceTypeId` (String, Required, Reference to ServiceType)
- `quantity` (Int(64), Required)
- `laborMinutes` (Int(64), Required)
- `metalUsageGrams` (Double, Optional)
- `metalType` (String, Optional)
- `unitPrice` (Double, Required)
- `lineTotal` (Double, Required)
- `notes` (String, Optional)

### ServiceType
- `companyId` (String, Required, Reference to Company)
- `name` (String, Required)
- `category` (String, Required)
- `defaultSku` (String, Required)
- `defaultLaborMinutes` (Int(64), Required)
- `defaultMetalUsageGrams` (Double, Optional)
- `baseRetail` (Double, Required)
- `baseCost` (Double, Required)
- `pricingFormulaId` (String, Optional)
- `isActive` (Int(64), Required)
- `isGenericSku` (Int(64), Required)
- `requiresSpringersCheck` (Int(64), Required)
- `metalTypes` (String List, Required)
- `sizingCategory` (String, Optional)
- `watchBrand` (String, Optional)
- `estimateRequired` (Int(64), Required)
- `vendorService` (Int(64), Required)
- `qualityControlRequired` (Int(64), Required)

### PricingRule
- `companyId` (String, Required, Reference to Company)
- `name` (String, Required)
- `description` (String, Required)
- `formulaDefinition` (String, Required) - JSON encoded
- `allowManualOverride` (Int(64), Required)
- `requireManagerApprovalIfOverrideExceedsPercent` (Double, Required)
- `isActive` (Int(64), Required)
- `appliesToServiceCategory` (String, Optional)

### MetalMarketRate
- `companyId` (String, Required, Reference to Company)
- `metalType` (String, Required)
- `unit` (String, Required)
- `rate` (Double, Required)
- `effectiveDate` (Date/Time, Required)
- `isActive` (Int(64), Required)

### LaborRate
- `companyId` (String, Required, Reference to Company)
- `role` (String, Required)
- `ratePerHour` (Double, Required)
- `effectiveDate` (Date/Time, Required)
- `isActive` (Int(64), Required)

### QuotePhoto
- `quoteId` (String, Required, Reference to Quote)
- `photoData` (Asset, Required) - CloudKit Asset
- `caption` (String, Optional)
- `uploadedAt` (Date/Time, Required)

### IntakeChecklist
- `quoteId` (String, Required, Reference to Quote)
- `completedByUserId` (String, Required, Reference to User)
- `completedAt` (Date/Time, Required)
- `springersItemVerified` (Int(64), Required)
- `itemDescription` (String, Optional)
- `conditionNotes` (String, Optional)
- `photosTaken` (Int(64), Required)
- `measurementsTaken` (Int(64), Required)
- `metalTested` (Int(64), Required)
- `stoneCheckCompleted` (Int(64), Required)
- `customerExpectationsDiscussed` (Int(64), Required)

### LooseDiamondDocumentation
- `quoteId` (String, Required, Reference to Quote)
- `lineItemId` (String, Required)
- `caratWeight` (Double, Required)
- `colorGrade` (String, Optional)
- `clarityGrade` (String, Optional)
- `cutGrade` (String, Optional)
- `certificateNumber` (String, Optional)
- `lab` (String, Optional)
- `dimensions` (String, Optional)
- `photoAssetId` (String, Optional)

### CommunicationLog
- `quoteId` (String, Required, Reference to Quote)
- `userId` (String, Required, Reference to User)
- `communicationType` (String, Required)
- `message` (String, Required)
- `timestamp` (Date/Time, Required)
- `recipientEmail` (String, Optional)
- `recipientPhone` (String, Optional)

### AppraisalService
- `quoteId` (String, Required, Reference to Quote)
- `guestId` (String, Required, Reference to Guest)
- `appraiserId` (String, Required, Reference to User)
- `appraisalType` (String, Required)
- `pricingTier` (String, Required)
- `itemCount` (Int(64), Required)
- `largestCaratWeight` (Double, Required)
- `calculatedFee` (Double, Required)
- `finalFee` (Double, Required)
- `feeOverrideReason` (String, Optional)
- `createdAt` (Date/Time, Required)
- `scheduledDate` (Date/Time, Optional)
- `completedDate` (Date/Time, Optional)
- `expedited` (Int(64), Required)
- `expediteMultiplier` (Double, Required)
- `sarinReportRequested` (Int(64), Required)
- `gemIdRequested` (Int(64), Required)
- `photoDocumentation` (Int(64), Required)
- `certificationVerification` (Int(64), Required)
- `isUpdate` (Int(64), Required)
- `originalAppraisalDate` (Date/Time, Optional)
- `updateDiscount` (Double, Optional)
- `status` (String, Required)
- `deliveryMethod` (String, Required)
- `notes` (String, Optional)

### VendorIntegration (if applicable)
- `companyId` (String, Required, Reference to Company)
- `vendorName` (String, Required)
- `apiEndpoint` (String, Required)
- `apiKey` (String, Required)
- `isActive` (Int(64), Required)

## Database Settings

### Private Database

All record types should be stored in the **Private Database** (default for CloudKit apps).

### Security Roles

1. In CloudKit Console, go to **Schema** → **Security Roles**
2. Configure permissions:
   - **World**: Read/Write (for authenticated users)
   - **Creator**: Full Access

### Indexes

Add indexes for frequently queried fields:

- **Company**: `companyId` (Queryable)
- **Store**: `companyId` (Queryable), `storeCode` (Queryable)
- **User**: `companyId` (Queryable), `role` (Queryable), `email` (Queryable)
- **Quote**: `companyId` (Queryable), `storeId` (Queryable), `guestId` (Queryable), `status` (Queryable)
- **Guest**: `companyId` (Queryable), `storeId` (Queryable), `email` (Queryable)

## Verification

After setting up the schema:

1. **Run the app** - The bootstrap service will create initial data
2. **Check CloudKit Console** → **Data** → **Record Types** to see created records
3. **Verify authentication** - Try logging in with the credentials that were created during bootstrap

## Troubleshooting

### "Record Type Not Found" Error
- Ensure the record type exists in CloudKit Console
- Check that field names match exactly (case-sensitive)
- Verify the container identifier matches your entitlements

### Authentication Fails
- Ensure bootstrap has run successfully
- Check that users exist in CloudKit database
- Verify CloudKit account status in app logs

### Schema Changes
- If you modify the schema, you may need to reset the development database
- Go to CloudKit Console → **Data** → **Development** → **Reset Development Data**

## Next Steps

After schema is set up:

1. Run the app - it will automatically bootstrap initial data
2. Login with credentials (created during bootstrap):
   - **SUPERADMIN**: `SUPERadmin` / `SUPERadmin`
   - **ADMIN**: `admin` / `admin`
3. Verify data appears in CloudKit Console

**Important**: Change these default credentials in production!

