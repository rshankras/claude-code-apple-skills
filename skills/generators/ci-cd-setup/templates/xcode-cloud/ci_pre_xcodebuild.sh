#!/bin/bash
# ci_pre_xcodebuild.sh
# Xcode Cloud: Runs before xcodebuild starts
#
# Use this script for:
# - Running code generation (SwiftGen, Sourcery, etc.)
# - Updating version/build numbers
# - Final configuration before build
#
# Available environment variables:
# - CI_PRODUCT: Product name
# - CI_XCODE_SCHEME: Scheme being built
# - CI_BUILD_NUMBER: Xcode Cloud build number
# - CI_TAG: Git tag (if triggered by tag)

set -e  # Exit on error

echo "🔧 Running pre-xcodebuild script..."
echo "Product: $CI_PRODUCT"
echo "Scheme: $CI_XCODE_SCHEME"

# ============================================
# Code Generation
# ============================================

# SwiftGen (if installed and configured)
# if command -v swiftgen &> /dev/null; then
#     echo "Running SwiftGen..."
#     swiftgen
# fi

# Sourcery (if installed and configured)
# if command -v sourcery &> /dev/null; then
#     echo "Running Sourcery..."
#     sourcery
# fi

# ============================================
# Update Build Number
# ============================================

# Option 1: Use Xcode Cloud build number
# This updates the CFBundleVersion in Info.plist

# Find the project
# PROJECT_PATH=$(find "$CI_WORKSPACE" -name "*.xcodeproj" | head -1)

# if [ -n "$PROJECT_PATH" ]; then
#     echo "Updating build number to $CI_BUILD_NUMBER..."
#     cd "$(dirname "$PROJECT_PATH")"
#     agvtool new-version -all "$CI_BUILD_NUMBER"
# fi

# Option 2: Generate build number from date
# BUILD_NUMBER=$(date +%Y%m%d%H%M)
# agvtool new-version -all "$BUILD_NUMBER"

# ============================================
# Update Version for Tags
# ============================================

# If triggered by a tag, extract version
# if [ -n "$CI_TAG" ]; then
#     # Extract version from tag (e.g., v1.2.3 -> 1.2.3)
#     VERSION=${CI_TAG#v}
#     echo "Setting marketing version to $VERSION..."
#     agvtool new-marketing-version "$VERSION"
# fi

# ============================================
# Environment-specific Build Settings
# ============================================

# Create xcconfig for environment-specific settings
# Uncomment and customize as needed

# XCCONFIG_PATH="$CI_WORKSPACE/CI.xcconfig"
#
# case "$CI_BRANCH" in
#     "main" | "master")
#         cat > "$XCCONFIG_PATH" << EOF
# // Production configuration
# API_BASE_URL = https://api.yourapp.com
# ENABLE_ANALYTICS = YES
# EOF
#         ;;
#     "develop")
#         cat > "$XCCONFIG_PATH" << EOF
# // Staging configuration
# API_BASE_URL = https://staging.yourapp.com
# ENABLE_ANALYTICS = YES
# EOF
#         ;;
#     *)
#         cat > "$XCCONFIG_PATH" << EOF
# // Development configuration
# API_BASE_URL = https://dev.yourapp.com
# ENABLE_ANALYTICS = NO
# EOF
#         ;;
# esac

# ============================================
# Run Linters
# ============================================

# SwiftLint (optional - can slow down builds)
# if command -v swiftlint &> /dev/null; then
#     echo "Running SwiftLint..."
#     swiftlint lint --quiet || true  # Don't fail on lint warnings
# fi

# ============================================
# Pre-build Checks
# ============================================

# Verify required files exist
# if [ ! -f "$CI_WORKSPACE/GoogleService-Info.plist" ]; then
#     echo "⚠️ Warning: GoogleService-Info.plist not found"
# fi

echo "✅ Pre-xcodebuild script completed"
