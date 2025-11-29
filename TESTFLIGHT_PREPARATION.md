# TestFlight Preparation Guide

## Current Configuration

Your project is now configured for TestFlight deployment. Here's what has been set up:

### Version Information
- **Version**: 1.0 (CFBundleShortVersionString)
- **Build**: 1 (CFBundleVersion)
- **Bundle Identifier**: com.jewelryrepair.RepairPriceEstimator

### Project Settings
- ✅ Release configuration optimized for production
- ✅ Debug symbols enabled (DWARF with dSYM)
- ✅ Swift optimization level set to -O for Release builds
- ✅ CloudKit entitlements configured
- ✅ Automatic code signing enabled

## Steps to Archive and Upload to TestFlight

### 1. Open Project in Xcode
```bash
open RepairPriceEstimator.xcodeproj
```

### 2. Configure Signing & Capabilities

1. **Select the RepairPriceEstimator target** in Xcode
2. Go to **Signing & Capabilities** tab
3. **Enable "Automatically manage signing"** if not already enabled
4. **Select your Development Team** from the dropdown
   - You must have an active Apple Developer account
   - Team ID will be automatically filled once selected

### 3. Verify Entitlements

1. Ensure **RepairPriceEstimator.entitlements** is properly configured:
   - CloudKit container: `iCloud.com.jewelryrepair.estimator`
   - CloudKit services enabled
   - Data protection: Complete

### 4. Update Version/Build Numbers (Optional)

Before archiving, you may want to increment the build number:
- In Xcode: Target → General → Version/Build
- Or update in `project.yml`:
  - `INFOPLIST_KEY_CFBundleShortVersionString` (version)
  - `INFOPLIST_KEY_CFBundleVersion` (build number)

### 5. Create Archive

**Option A: Using Xcode GUI**
1. Select **Any iOS Device** (not a simulator) from the device dropdown
2. Go to **Product → Archive**
3. Wait for the archive to complete
4. The Organizer window will open automatically

**Option B: Using Command Line**
```bash
# Clean build folder
xcodebuild clean -project RepairPriceEstimator.xcodeproj -scheme RepairPriceEstimator

# Create archive
xcodebuild archive \
  -project RepairPriceEstimator.xcodeproj \
  -scheme RepairPriceEstimator \
  -configuration Release \
  -archivePath "./build/RepairPriceEstimator.xcarchive" \
  CODE_SIGN_IDENTITY="Apple Development" \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID"
```

### 6. Upload to TestFlight

**Option A: Using Xcode Organizer**
1. In the Organizer window, select your archive
2. Click **Distribute App**
3. Select **App Store Connect**
4. Follow the wizard:
   - Distribution method: **Upload**
   - Select signing options (usually "Automatically manage signing")
   - Review app information
   - Upload

**Option B: Using Command Line (requires Xcode 13+)**
```bash
# Export IPA for App Store
xcodebuild -exportArchive \
  -archivePath "./build/RepairPriceEstimator.xcarchive" \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath "./build"

# Then upload using altool or transporter
xcrun altool --upload-app \
  --type ios \
  --file "./build/RepairPriceEstimator.ipa" \
  --username "your-apple-id@email.com" \
  --password "@keychain:Application Loader: your-apple-id@email.com"
```

### 7. Complete App Store Connect Setup

Before uploading, ensure in App Store Connect:

1. **App Information**
   - Create app record if it doesn't exist
   - Bundle ID: `com.jewelryrepair.RepairPriceEstimator`
   - App name: "Repair Price Estimator" (or your preferred name)
   - Primary language: English

2. **App Privacy**
   - Complete Privacy Questionnaire
   - Declare data collection practices (CloudKit sync, user accounts)

3. **TestFlight Information**
   - Add test information (What to Test notes)
   - Add testers (Internal/External groups)
   - Provide screenshots if needed

### 8. CloudKit Schema Deployment

**CRITICAL**: Before submitting to TestFlight, deploy your CloudKit schema to Production:

1. Go to [CloudKit Console](https://icloud.developer.apple.com/dashboard)
2. Select container: `iCloud.com.jewelryrepair.estimator`
3. Go to **Schema → Production**
4. Click **"Deploy Schema Changes"** (from Development to Production)
5. Review and confirm all record types
6. **Wait for deployment to complete** (can take several minutes)

**Important Notes:**
- Production schema cannot be deleted once deployed
- Field modifications require careful migration planning
- Test thoroughly in Development environment first

### 9. App Store Metadata (for TestFlight)

Prepare the following for TestFlight:
- **What to Test** notes (what features to focus on)
- **App Description** (what the app does)
- **Support URL** (if available)
- **Marketing URL** (optional)
- **Screenshots** (required for App Store submission, optional for TestFlight)

### 10. Build Requirements Checklist

Before archiving, verify:
- ✅ All features work correctly
- ✅ CloudKit schema deployed to Production (if ready)
- ✅ No console errors or crashes
- ✅ App icons are included (if using custom icons)
- ✅ Launch screen is configured
- ✅ Privacy policy URL is set (if collecting user data)
- ✅ App Store Connect app record exists

### 11. Common Issues

**Issue: "No such module 'UIKit'"**
- Solution: This is a pre-commit hook issue with Swift Package Manager
- The Xcode build works fine, ignore this for commits

**Issue: Code signing errors**
- Ensure your Apple Developer account is active
- Verify Team ID is set correctly
- Check certificates in Keychain Access

**Issue: CloudKit not working in TestFlight**
- Verify schema is deployed to Production
- Check container identifier matches exactly
- Ensure entitlements are included in archive

### 12. Version Numbering Best Practices

- **Version (CFBundleShortVersionString)**: Semantic version (1.0, 1.1, 2.0)
- **Build (CFBundleVersion)**: Increment with each upload (1, 2, 3...)
- TestFlight allows multiple builds with same version but different build numbers

## Quick Command Reference

```bash
# Regenerate Xcode project
xcodegen generate

# Clean build
xcodebuild clean -project RepairPriceEstimator.xcodeproj -scheme RepairPriceEstimator

# Build for device
xcodebuild -project RepairPriceEstimator.xcodeproj \
  -scheme RepairPriceEstimator \
  -configuration Release \
  -destination 'generic/platform=iOS'

# Create archive
xcodebuild archive \
  -project RepairPriceEstimator.xcodeproj \
  -scheme RepairPriceEstimator \
  -configuration Release \
  -archivePath "./build/RepairPriceEstimator.xcarchive"
```

## Next Steps

1. Open the project in Xcode
2. Configure your Development Team
3. Create an archive
4. Upload to TestFlight via Xcode Organizer
5. Complete App Store Connect setup
6. Add testers and distribute

Good luck with your TestFlight submission! 🚀

