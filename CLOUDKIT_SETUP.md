# CloudKit Setup Instructions

## Current Issue: Blank Screen & CloudKit Entitlements Error

The app is showing a blank screen because CloudKit entitlements are not being properly embedded in the app bundle during code signing.

## Fix Steps

### 1. Configure Code Signing in Xcode

1. Open `RepairPriceEstimator.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the **RepairPriceEstimator** target
4. Go to **Signing & Capabilities** tab
5. **Enable "Automatically manage signing"**
6. Select your **Team** (create a personal team if needed)
7. Verify that **CloudKit** capability is shown in the capabilities list
8. If CloudKit capability is missing:
   - Click **+ Capability**
   - Add **CloudKit**
   - Container should be: `iCloud.com.jewelryrepair.estimator`

### 2. Verify Entitlements File

The `RepairPriceEstimator.entitlements` file should contain:
```xml
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

### 3. Clean and Rebuild

1. In Xcode: **Product > Clean Build Folder** (Shift+Cmd+K)
2. **Product > Build** (Cmd+B)
3. **Product > Run** (Cmd+R)

### 4. For Simulator Testing

Even in the simulator, you need:
- Proper code signing with a development team
- iCloud sign-in on the simulator (Settings > Sign in to your iPhone)

## Temporary Workaround

If you just want to see the UI work without CloudKit:

1. The app should still show the login screen even if CloudKit fails
2. Check the Xcode console for the debug messages I added
3. The blank screen might be a view rendering issue - check if you see any console output

## Verify Entitlements Are Embedded

After building, you can verify entitlements are embedded:
```bash
codesign -d --entitlements - /path/to/RepairPriceEstimator.app
```

This should show the CloudKit entitlements if they're properly embedded.

