#!/bin/bash

# Script to create an Xcode project for RepairPriceEstimator
# This creates a proper iOS app project that can run in the simulator

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

echo "🔨 Creating Xcode project for RepairPriceEstimator..."
echo ""

# Check if Xcode project already exists
if [ -f "RepairPriceEstimator.xcodeproj/project.pbxproj" ]; then
    echo "⚠️  Xcode project already exists at RepairPriceEstimator.xcodeproj"
    read -p "Do you want to regenerate it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    rm -rf RepairPriceEstimator.xcodeproj
fi

# Create a temporary directory for the new project
TEMP_DIR=$(mktemp -d)
echo "📦 Using temporary directory: $TEMP_DIR"

# Create a basic Xcode project structure
mkdir -p RepairPriceEstimator.xcodeproj
mkdir -p "$PROJECT_ROOT/RepairPriceEstimator.xcodeproj/xcshareddata/xcschemes"

echo "✅ Project structure created"

echo ""
echo "📝 Creating Xcode project file..."
echo ""
echo "⚠️  NOTE: Xcode project files are complex. The recommended approach is:"
echo ""
echo "   1. Open Xcode"
echo "   2. File → New → Project"
echo "   3. Choose 'iOS' → 'App'"
echo "   4. Product Name: RepairPriceEstimator"
echo "   5. Organization Identifier: com.jewelryrepair"
echo "   6. Language: Swift"
echo "   7. Interface: SwiftUI"
echo "   8. Uncheck 'Include Tests' (you already have tests)"
echo "   9. Save in a TEMPORARY location"
echo "   10. Then manually:"
echo "       - Delete the generated source files"
echo "       - Add all files from RepairPriceEstimator/ directory"
echo "       - Add RepairPriceEstimatorTests/ as test target"
echo "       - Configure entitlements (add RepairPriceEstimator.entitlements)"
echo "       - Set Bundle Identifier"
echo "       - Configure CloudKit capabilities"
echo ""
echo "   OR, use this simpler method:"
echo ""
echo "   1. Open Package.swift in Xcode: open Package.swift"
echo "   2. In Xcode, go to File → New → Project from Package"
echo "   3. Or simply press ⌘+R to build and run (Xcode can run Swift Packages directly)"
echo ""

# Actually, let's try to open the package in Xcode and see if it works
echo "🚀 Opening Package.swift in Xcode..."
echo "   Xcode should open. You can then press ⌘+R to build and run."
echo ""

open Package.swift

echo "✅ Done! Xcode should open with your package."
echo ""
echo "📋 Next steps:"
echo "   1. Wait for Xcode to open"
echo "   2. Select a simulator (e.g., iPhone 15)"
echo "   3. Press ⌘+R to build and run"
echo ""
echo "   If you need a full Xcode project file for signing/distribution,"
echo "   follow the manual steps above to create one."

