#!/bin/bash

# RepairPriceEstimator Test Script
# Runs comprehensive tests with coverage reporting

set -e

echo "🧪 Running RepairPriceEstimator Tests..."

# Clean and build
swift package clean
swift build

# Run tests with verbose output
echo "📊 Running unit tests..."
swift test --parallel --verbose

# Check test coverage (basic)
echo "📈 Analyzing test coverage..."
find RepairPriceEstimatorTests -name "*.swift" | wc -l | awk '{print "Test files: " $1}'
find RepairPriceEstimator -name "*.swift" -path "*/Services/*" | wc -l | awk '{print "Service files: " $1}'
find RepairPriceEstimator -name "*.swift" -path "*/Models/*" | wc -l | awk '{print "Model files: " $1}'

# Run specific test suites
echo "🎯 Running pricing engine tests..."
swift test --filter PricingEngineTests

echo "⚡ Running rush multiplier tests..."
swift test --filter RushMultiplierTests

echo "✅ All tests completed!"
