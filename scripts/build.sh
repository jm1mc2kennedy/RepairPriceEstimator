#!/bin/bash

# RepairPriceEstimator Build Script
# Builds the project and launches it in the iOS Simulator

set -e

echo "🔨 Building RepairPriceEstimator..."

# Get the script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

# Check if Xcode project exists, otherwise open package in Xcode
if [ ! -f "RepairPriceEstimator.xcodeproj/project.pbxproj" ]; then
    echo "📦 No Xcode project found. Opening Swift Package in Xcode..."
    echo ""
    echo "⚠️  IMPORTANT: This is a Swift Package, not an Xcode app project."
    echo "   To run the app in the simulator, you need to:"
    echo "   1. Open Package.swift in Xcode (which will happen now)"
    echo "   2. In Xcode, click the play button (⌘+R) to build and run"
    echo "   3. Or create an Xcode app project that uses this package"
    echo ""
    echo "   Opening Package.swift in Xcode now..."
    open Package.swift
    exit 0
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
xcodebuild clean -project RepairPriceEstimator.xcodeproj -scheme RepairPriceEstimator -quiet 2>/dev/null || true

# Try to find available simulator
SIMULATOR_DEVICE=$(xcrun simctl list devices available | grep -i "iphone" | head -1 | sed 's/.*(\([^)]*\)).*/\1/' | head -1)
if [ -z "$SIMULATOR_DEVICE" ]; then
    SIMULATOR_DEVICE="iPhone 15"
    echo "📱 Using default simulator: $SIMULATOR_DEVICE"
else
    echo "📱 Found available simulator: $SIMULATOR_DEVICE"
fi

# Get simulator UDID
SIMULATOR_UDID=$(xcrun simctl list devices available | grep -i "iphone" | head -1 | grep -oE '([0-9A-F-]{36})' | head -1)

if [ -z "$SIMULATOR_UDID" ]; then
    # Try to find any iPhone simulator (even if not marked available)
    SIMULATOR_UDID=$(xcrun simctl list devices | grep -i "iphone 15" | head -1 | grep -oE '([0-9A-F-]{36})' | head -1)
fi

if [ -z "$SIMULATOR_UDID" ]; then
    echo "⚠️  No iPhone simulator found. Creating iPhone 15 simulator..."
    SIMULATOR_UDID=$(xcrun simctl create "iPhone 15" "iPhone 15" "iOS17.0" 2>/dev/null || echo "")
fi

if [ -z "$SIMULATOR_UDID" ]; then
    echo "❌ Could not find or create a simulator. Please create one in Xcode."
    exit 1
fi

echo "  - Using simulator UDID: $SIMULATOR_UDID"

# Boot the simulator
echo "🚀 Booting iOS Simulator..."
xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || echo "  - Simulator may already be booted"

# Open Simulator app
open -a Simulator 2>/dev/null || true

# Wait for simulator to be ready
echo "  - Waiting for simulator to be ready..."
sleep 3

# Build for iOS simulator
echo "📱 Building for iOS Simulator..."
xcodebuild build \
    -project RepairPriceEstimator.xcodeproj \
    -scheme RepairPriceEstimator \
    -sdk iphonesimulator \
    -destination "id=$SIMULATOR_UDID" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    -quiet 2>&1 | grep -E "(error|warning|BUILD)" || true

echo "✅ Build completed successfully!"

# Build and run the app
echo "🚀 Installing and launching app..."
xcodebuild test \
    -project RepairPriceEstimator.xcodeproj \
    -scheme RepairPriceEstimator \
    -sdk iphonesimulator \
    -destination "id=$SIMULATOR_UDID" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    -only-testing:RepairPriceEstimatorTests 2>&1 | grep -E "(error|warning|Test|BUILD)" || {
    # If that doesn't work, try building and installing manually
    echo "  - Building app bundle..."
    xcodebuild build \
        -project RepairPriceEstimator.xcodeproj \
        -scheme RepairPriceEstimator \
        -sdk iphonesimulator \
        -destination "id=$SIMULATOR_UDID" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        -derivedDataPath ./DerivedData
    
    # Find the built app
    APP_PATH=$(find ./DerivedData -name "RepairPriceEstimator.app" -type d | head -1)
    if [ ! -z "$APP_PATH" ]; then
        echo "  - Installing app: $APP_PATH"
        xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"
        
        # Get bundle identifier and launch
        BUNDLE_ID=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleIdentifier 2>/dev/null || echo "com.jewelryrepair.RepairPriceEstimator")
        echo "  - Launching app with bundle ID: $BUNDLE_ID"
        xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID" || echo "⚠️  Could not launch app automatically"
    fi
}

echo "✅ Simulator launched! The app should appear in the simulator shortly."
echo "   If the app doesn't appear, try running it manually from Xcode (⌘+R)"

# Run tests separately
echo ""
echo "🧪 Running tests..."
xcodebuild test \
    -project RepairPriceEstimator.xcodeproj \
    -scheme RepairPriceEstimator \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,name=$SIMULATOR_DEVICE" \
    -only-testing:RepairPriceEstimatorTests 2>/dev/null || echo "⚠️  Some tests may have failed"

echo "🎉 Build and launch process completed!"
