# CloudKit Schema Import Instructions

## Problem
The console shows `CKAccountStatus(rawValue: 3)` which means `couldNotDetermine` - CloudKit is not properly signed in or configured. Authentication fails with `notSignedInToiCloud` error.

## Solution: Import Schema Manually

### Step 1: Access CloudKit Console

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Sign in with your Apple ID
3. Navigate to **Certificates, Identifiers & Profiles**
4. Click **Identifiers** → **CloudKit Containers**
5. Find or create container: `iCloud.com.jewelryrepair.estimator`
6. Click on the container → **CloudKit Console** button

### Step 2: Import Schema

1. In CloudKit Console, go to **Schema** → **Record Types**
2. For each record type in `cloudkit_schema.sql`:
   - Click **New Record Type** (or edit if it exists)
   - Copy the `DEFINE SCHEMA` block for that record type
   - Paste it into the schema editor
   - Click **Save**

### Step 3: Required Record Types (in order)

Import these in order to avoid reference errors:

1. **Company** (no dependencies)
2. **Store** (depends on Company)
3. **User** (depends on Company)
4. **Guest** (depends on Company, Store)
5. **ServiceType** (depends on Company)
6. **PricingRule** (depends on Company)
7. **MetalMarketRate** (depends on Company)
8. **LaborRate** (depends on Company)
9. **Quote** (depends on Company, Store, Guest)
10. **QuoteLineItem** (depends on Quote, ServiceType)
11. **QuotePhoto** (depends on Quote)
12. **IntakeChecklist** (depends on Quote, User)
13. **LooseDiamondDocumentation** (depends on Quote)
14. **CommunicationLog** (depends on Quote, User)
15. **AppraisalService** (depends on Quote, Guest, User)
16. **VendorIntegration** (depends on Company)

### Step 4: Configure Indexes

After importing all record types, add indexes for queryable fields:

1. Go to **Schema** → **Record Types** → Select a record type → **Indexes**
2. Add indexes for these fields:

**Company**:
- No indexes needed (small dataset)

**Store**:
- `companyId` (Queryable)

**User**:
- `companyId` (Queryable)
- `role` (Queryable)
- `email` (Queryable)

**Guest**:
- `companyId` (Queryable)
- `storeId` (Queryable)
- `email` (Queryable)

**Quote**:
- `companyId` (Queryable)
- `storeId` (Queryable)
- `guestId` (Queryable)
- `status` (Queryable)

**ServiceType**:
- `companyId` (Queryable)

**PricingRule**:
- `companyId` (Queryable)

**MetalMarketRate**:
- `companyId` (Queryable)

**LaborRate**:
- `companyId` (Queryable)

### Step 5: Verify and Deploy

1. Review all record types in **Schema** → **Record Types**
2. Ensure all fields match the definitions in `cloudkit_schema.sql`
3. Go to **Deploy Schema Changes** → **Deploy to Development**

### Step 6: Sign In to iCloud

**On Simulator:**
1. Open **Settings** app
2. Tap **Sign in to your iPhone**
3. Use your Apple ID credentials
4. Enable iCloud Drive if prompted

**On Device:**
1. Ensure you're signed in to iCloud in Settings
2. Verify iCloud Drive is enabled

### Step 7: Test

1. Run the app again
2. Check console for CloudKit status - should be `available` not `couldNotDetermine`
3. The bootstrap service should create initial data automatically
4. After bootstrap completes, you can log in

## Troubleshooting

### CloudKit Status Still `couldNotDetermine`
- Verify iCloud is signed in on device/simulator
- Check that entitlements are properly configured in Xcode
- Ensure CloudKit capability is enabled in Xcode project

### Authentication Still Fails
- Wait for bootstrap to complete (check console logs)
- Verify users were created in CloudKit Console → Data → Record Types → User
- Try signing out and back in to iCloud

### Schema Import Errors
- Ensure all fields match exactly (case-sensitive)
- Check that LIST types use `LIST<STRING>` format
- Verify ASSET types are specified correctly

## Important Notes

- **Development vs Production**: Changes are deployed to Development first, then to Production when ready
- **Data Reset**: You can reset development data in CloudKit Console if needed
- **Schema Changes**: Once data exists, schema changes may require data migration

