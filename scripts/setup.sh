#!/bin/bash

# RepairPriceEstimator Development Setup Script
# Sets up the development environment and dependencies

set -e

echo "🚀 Setting up RepairPriceEstimator development environment..."

# Check Swift version
echo "📋 Checking Swift version..."
swift --version

# Check Xcode version (if available)
if command -v xcodebuild &> /dev/null; then
    echo "📋 Checking Xcode version..."
    xcodebuild -version
fi

# Resolve package dependencies
echo "📦 Resolving package dependencies..."
swift package resolve

# Create necessary directories
echo "📁 Creating development directories..."
mkdir -p build_logs
mkdir -p documentation
mkdir -p resources

# Set up git hooks (optional)
echo "🪝 Setting up git hooks..."
if [ ! -f .git/hooks/pre-commit ]; then
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Run basic checks before commit
echo "🔍 Running pre-commit checks..."

# Check for Swift compilation
swift build --quiet || {
    echo "❌ Build failed - commit aborted"
    exit 1
}

# Run quick tests
swift test --quiet || {
    echo "❌ Tests failed - commit aborted"
    exit 1
}

echo "✅ Pre-commit checks passed"
EOF
    chmod +x .git/hooks/pre-commit
fi

# Create build configuration
echo "⚙️ Creating build configuration..."
cat > .swiftpm/configuration/Package.resolved << 'EOF'
{
  "pins": [],
  "version": 3
}
EOF

# Setup complete
echo "✅ Development environment setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Run './scripts/build.sh' to build the project"
echo "  2. Run './scripts/test.sh' to run tests"
echo "  3. Start developing with your favorite editor"
echo ""
echo "🔧 Available scripts:"
echo "  - ./scripts/build.sh    - Build the project"
echo "  - ./scripts/test.sh     - Run tests"
echo "  - ./scripts/lint.sh     - Code linting (if created)"
echo ""
