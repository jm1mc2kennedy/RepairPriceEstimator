#!/bin/bash

# RepairPriceEstimator Run Script
# Opens the project in Xcode and launches the simulator

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

echo "🚀 RepairPriceEstimator - Quick Run Script"
echo ""

# Launch simulator first
echo "🚀 Launching iOS Simulator..."
SIMULATOR_DEVICE="iPhone 15"
SIMULATOR_UDID=$(xcrun simctl list devices available | grep -i "iphone 15" | head -1 | grep -oE '([0-9A-F-]{36})' | head -1)

if [ -z "$SIMULATOR_UDID" ]; then
    SIMULATOR_UDID=$(xcrun simctl list devices available | grep -i "iphone" | head -1 | grep -oE '([0-9A-F-]{36})' | head -1)
    if [ ! -z "$SIMULATOR_UDID" ]; then
        SIMULATOR_DEVICE=$(xcrun simctl list devices available | grep "$SIMULATOR_UDID" | sed 's/.*iPhone \([^)]*\).*/iPhone \1/' | head -1)
    fi
fi

if [ ! -z "$SIMULATOR_UDID" ]; then
    echo "   - Found simulator: $SIMULATOR_DEVICE ($SIMULATOR_UDID)"
    xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || echo "   - Simulator may already be booted"
    open -a Simulator 2>/dev/null || true
    echo "   ✅ Simulator launched!"
else
    echo "   ⚠️  No simulator found. Xcode will prompt you to create one."
fi

echo ""

# Check if Xcode project exists
if [ -f "RepairPriceEstimator.xcodeproj/project.pbxproj" ]; then
    echo "📱 Opening Xcode project..."
    open RepairPriceEstimator.xcodeproj
    
    echo ""
    echo "✅ Xcode opened with your project."
    echo ""
    echo "📋 Next steps:"
    echo "   1. Wait for Xcode to finish loading"
    echo "   2. Select '$SIMULATOR_DEVICE' or another simulator from the device menu"
    echo "   3. Press ⌘+R to build and run"
else
    echo "📦 Opening Swift Package in Xcode..."
    open Package.swift
    
    echo ""
    echo "✅ Xcode opened with your Swift Package."
    echo ""
    echo "📋 Next steps:"
    echo "   1. Wait for Xcode to finish loading the package"
    echo "   2. In the top toolbar, select a simulator (e.g., $SIMULATOR_DEVICE)"
    echo "   3. Press ⌘+R to build and run"
    echo ""
    echo "⚠️  Note: Running from Swift Package works for development, but for:"
    echo "   - Code signing"
    echo "   - App Store distribution"
    echo "   - Proper entitlements configuration"
    echo "   You'll need to create an Xcode app project."
    echo ""
    echo "   To create one, run: ./scripts/create-xcode-project.sh"
fi

echo ""
echo "✅ Setup complete! The simulator should be ready."

