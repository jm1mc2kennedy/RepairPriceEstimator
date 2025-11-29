# App Store Connect Setup Guide

## Issue: App Record Not Found

You're seeing these errors because the app record doesn't exist in App Store Connect yet. You need to create it first before uploading.

## Step-by-Step: Create App Record

### 1. Log into App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple Developer account credentials
3. Navigate to **"My Apps"**

### 2. Create New App

1. Click the **"+"** button (top left) or **"Add App"** button
2. Fill in the following information:

   **Platforms:**
   - Select **iOS**

   **Name:**
   - Enter: `Repair Price Estimator` (or your preferred app name)
   - This is the display name users will see

   **Primary Language:**
   - Select: **English (U.S.)**

   **Bundle ID:**
   - Select: `com.jewelryrepair.RepairPriceEstimator`
   - If it doesn't appear, you need to register it first (see below)

   **SKU:**
   - Enter a unique identifier: `repair-price-estimator-001`
   - This is for your internal tracking, not visible to users

   **User Access:**
   - Select **Full Access** (for yourself) or **App Manager** (if you want to grant access to others)

3. Click **"Create"**

### 3. Register Bundle ID (If Not Available)

If `com.jewelryrepair.RepairPriceEstimator` doesn't appear in the Bundle ID dropdown:

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **App IDs**
4. Click the **"+"** button to create a new App ID
5. Select **App** under **Type**
6. Fill in:
   - **Description**: Repair Price Estimator
   - **Bundle ID**: Select **Explicit** and enter `com.jewelryrepair.RepairPriceEstimator`
7. Under **Capabilities**, enable:
   - ✅ **CloudKit**
   - ✅ **Push Notifications** (if you plan to use them)
8. Click **Continue** and then **Register**
9. Wait a few minutes for the Bundle ID to propagate to App Store Connect
10. Return to App Store Connect and try creating the app again

### 4. Verify Version Number Format

The version string must follow semantic versioning format (e.g., "1.0.0" not just "1.0").

Update in Xcode after creating the app record:
- Go to your target's **General** tab
- Set **Version**: `1.0.0` (must have 3 parts for App Store)
- Set **Build**: `1` (increment this for each upload)

Or update in `project.yml`:
```yaml
INFOPLIST_KEY_CFBundleShortVersionString: "1.0.0"
INFOPLIST_KEY_CFBundleVersion: "1"
```

### 5. Complete App Information

After creating the app record, fill in required information:

**App Information:**
- Subtitle (optional): Short description
- Category: Select appropriate categories (e.g., Business, Productivity)
- Privacy Policy URL (required if collecting user data)
- Support URL
- Marketing URL (optional)

**Pricing and Availability:**
- Price: Select **Free** or set a price
- Availability: Select countries/regions

**App Privacy:**
- Complete the Privacy Questionnaire
- Declare data collection practices:
  - ✅ User ID (for authentication)
  - ✅ Email address (if collected)
  - ✅ Name (if collected)
  - ✅ CloudKit sync data

**Note:** You don't need all information filled out to upload a TestFlight build, but you'll need it for App Store submission.

### 6. Upload Build

Once the app record exists:

1. Return to Xcode
2. Create archive: **Product → Archive**
3. In Organizer, select your archive
4. Click **Distribute App**
5. Select **App Store Connect**
6. Click **Upload**
7. Follow the wizard:
   - Distribution options: Upload
   - Select automatic signing
   - Review and upload

### 7. Alternative: Create App Record from Xcode

Xcode can create the app record automatically:

1. In Xcode, go to **Window → Organizer** (or **Product → Archive** if you have an archive)
2. Click **Distribute App**
3. Select **App Store Connect**
4. If app doesn't exist, Xcode will prompt you to create it
5. Fill in the information in the wizard
6. Xcode will create the app record and upload in one step

## Quick Fix for Version String

If you're still getting version string errors, update the project:

```bash
# Edit project.yml to use 3-part version
# Change: INFOPLIST_KEY_CFBundleShortVersionString: "1.0"
# To:     INFOPLIST_KEY_CFBundleShortVersionString: "1.0.0"

# Then regenerate:
xcodegen generate
```

## Troubleshooting

**Error: "Invalid App Record Creator"**
- Solution: You must be the Account Holder or Admin in your Apple Developer account
- Verify your role in [Apple Developer Portal](https://developer.apple.com/account) → Membership

**Error: "Bundle ID not available"**
- Solution: Register the Bundle ID first (see Step 3 above)
- Wait 5-10 minutes after registration before creating app

**Error: "Version string format invalid"**
- Solution: Use semantic versioning: `1.0.0` (3 parts minimum)
- App Store Connect requires at least MAJOR.MINOR format, but 3 parts is recommended

**Error: "Missing required app information"**
- Solution: Fill in at minimum:
  - App Name
  - Category (Primary)
  - Privacy Policy URL (if collecting data)

## Next Steps After Creating App Record

1. ✅ App record created in App Store Connect
2. ✅ Version string updated to `1.0.0` format
3. ✅ Archive the app in Xcode
4. ✅ Upload to TestFlight
5. ✅ Wait for processing (usually 10-30 minutes)
6. ✅ Add testers and distribute build

Good luck! 🚀

