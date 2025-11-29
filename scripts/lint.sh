#!/bin/bash

# RepairPriceEstimator Linting Script
# Runs code quality checks and formatting validation

set -e

echo "🔍 Running RepairPriceEstimator code quality checks..."

# Check for common Swift issues
echo "🐛 Checking for common issues..."

# Check for force unwrapping
echo "  - Checking for force unwrapping..."
FORCE_UNWRAP_COUNT=$(find RepairPriceEstimator -name "*.swift" | xargs grep -c "!" || true)
if [ "$FORCE_UNWRAP_COUNT" -gt 0 ]; then
    echo "    ⚠️  Found $FORCE_UNWRAP_COUNT potential force unwraps"
    find RepairPriceEstimator -name "*.swift" | xargs grep -n "!" | head -5
else
    echo "    ✅ No force unwrapping found"
fi

# Check for TODO comments
echo "  - Checking for TODO comments..."
TODO_COUNT=$(find RepairPriceEstimator -name "*.swift" | xargs grep -c "TODO\|FIXME\|HACK" || true)
if [ "$TODO_COUNT" -gt 0 ]; then
    echo "    📝 Found $TODO_COUNT TODO/FIXME/HACK comments"
else
    echo "    ✅ No TODO comments found"
fi

# Check for proper async/await usage
echo "  - Checking async/await patterns..."
ASYNC_COUNT=$(find RepairPriceEstimator -name "*.swift" | xargs grep -c "async\|await" || true)
echo "    📊 Found $ASYNC_COUNT async/await usages"

# Check for @MainActor usage
echo "  - Checking @MainActor usage..."
MAINACTOR_COUNT=$(find RepairPriceEstimator -name "*.swift" | xargs grep -c "@MainActor" || true)
echo "    🎭 Found $MAINACTOR_COUNT @MainActor annotations"

# Check for Sendable conformance
echo "  - Checking Sendable conformance..."
SENDABLE_COUNT=$(find RepairPriceEstimator -name "*.swift" | xargs grep -c "Sendable" || true)
echo "    📦 Found $SENDABLE_COUNT Sendable conformances"

# Basic code metrics
echo "📊 Code metrics:"
SWIFT_FILES=$(find RepairPriceEstimator -name "*.swift" | wc -l)
SWIFT_LINES=$(find RepairPriceEstimator -name "*.swift" | xargs wc -l | tail -1 | awk '{print $1}')
echo "  - Swift files: $SWIFT_FILES"
echo "  - Lines of code: $SWIFT_LINES"

# File organization check
echo "🗂️ File organization check:"
echo "  - Models: $(find RepairPriceEstimator -path "*/Models/*" -name "*.swift" | wc -l) files"
echo "  - Services: $(find RepairPriceEstimator -path "*/Services/*" -name "*.swift" | wc -l) files"
echo "  - Views: $(find RepairPriceEstimator -path "*/Views/*" -o -path "*/Features/*" -name "*.swift" | wc -l) files"
echo "  - Tests: $(find RepairPriceEstimatorTests -name "*.swift" | wc -l) files"

echo "✅ Code quality checks completed!"
