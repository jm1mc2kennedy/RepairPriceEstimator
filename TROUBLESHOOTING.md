# Troubleshooting Guide

## Current Status

The code has been updated to handle CloudKit schema mismatches more gracefully. However, **the CloudKit schema still needs to be updated** for full functionality.

## What's Been Fixed

1. ✅ Removed invalid OR predicates - CloudKit doesn't support `OR` in all predicate contexts
2. ✅ Fixed all `isActive == YES` to `isActive == 1` (CloudKit stores booleans as INT64)
3. ✅ Changed default predicates to use simple field comparisons
4. ✅ Temporarily disabled saving `createdAt` to User records until schema is updated
5. ✅ Made sort descriptors safe (use email for User, name for Company/Store, etc.)

## Still Need To Do

**CRITICAL: Update CloudKit Schema**

1. Go to [CloudKit Console](https://icloud.developer.apple.com/dashboard)
2. Select container: `iCloud.com.jewelryrepair.estimator`  
3. Schema → Development
4. Import/reset schema with `cloudkit_schema.sql`
5. Ensure User has `createdAt TIMESTAMP QUERYABLE SORTABLE`

## Testing Steps

1. **Clean build** - Product → Clean Build Folder (Shift+Cmd+K)
2. **Delete app from simulator** - Long press app icon → Delete App
3. **Rebuild and run** - Product → Run (Cmd+R)
4. **Check console** for errors
5. **Try login** with:
   - Username: `admin` / Password: `admin`
   - Username: `SUPERadmin` / Password: `SUPERadmin`

## Common Errors

### "Unknown field 'createdAt'"
- **Cause**: Schema doesn't have createdAt field
- **Fix**: Update CloudKit schema or the field will be skipped (already handled in code)

### "Invalid predicate"
- **Cause**: Using unsupported predicate syntax
- **Fix**: Already fixed - predicates now use simple comparisons

### "No users found"
- **Cause**: Users weren't created or can't be queried
- **Fix**: Check console for bootstrap errors. Users should be created during bootstrap.

## Debug Console Output

Look for these messages:
- `✅ Bootstrap completed` - Bootstrap succeeded
- `✅ Created ADMIN user` - User was created
- `✅ Verification: Found X user(s)` - Users exist in database
- `📊 Found X user(s) with role` - Query succeeded

If you see errors, share the full console output for diagnosis.

