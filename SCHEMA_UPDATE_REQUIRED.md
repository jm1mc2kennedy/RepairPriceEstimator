# CloudKit Schema Update Required

## Issue
The app is failing with errors:
- "Field 'createdAt' is not marked queryable"
- "Unknown field 'createdAt'" (for User record type)

## Fixes Applied

### 1. Schema Changes (`cloudkit_schema.sql`)
- ✅ Added `createdAt TIMESTAMP QUERYABLE SORTABLE` to the `User` record type
- ✅ Made all `createdAt` fields **QUERYABLE** (previously some were only SORTABLE)
  - Company: `createdAt` is now QUERYABLE
  - All other record types with `createdAt` are now QUERYABLE

### 2. Code Changes
- ✅ Added `createdAt` field to `User` model
- ✅ Updated CloudKitService to use type-specific queryable fields instead of always using `createdAt`
- ✅ Updated BootstrapService and AuthService queries to use `name` for Company queries (instead of `createdAt`)

## Action Required

**You MUST re-import the CloudKit schema** with the updated `cloudkit_schema.sql` file:

1. Go to [CloudKit Console](https://icloud.developer.apple.com/dashboard)
2. Select your container: `iCloud.com.jewelryrepair.estimator`
3. Go to Schema → Development (or Production)
4. Click "Import Schema" or "Reset Schema"
5. Copy and paste the contents of `cloudkit_schema.sql`
6. Review and deploy the schema

### Key Changes in Schema:
- **User** record type now has `createdAt TIMESTAMP QUERYABLE SORTABLE`
- All `createdAt` fields are now marked as **QUERYABLE** (not just SORTABLE)

## Testing After Schema Update

After re-importing the schema:
1. Clean build the app
2. Delete the app from simulator/device (to clear cached schema)
3. Reinstall and launch
4. Try login/signup again

The errors should be resolved once the schema matches the code expectations.

