#!/bin/bash

# Ray-Ban Meta POC Project Setup Script
# Usage: ./scripts/setup.sh

set -e

echo "🕶️  Ray-Ban Meta POC Project Setup"
echo "=================================="

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -1)
echo "✅ Found $XCODE_VERSION"

# Check for Command Line Tools
if ! xcode-select -p &> /dev/null; then
    echo "📦 Installing Xcode Command Line Tools..."
    xcode-select --install
else
    echo "✅ Command Line Tools installed"
fi

# Check Swift version
SWIFT_VERSION=$(swift --version 2>&1 | head -1)
echo "✅ $SWIFT_VERSION"

# Create directories if needed
echo ""
echo "📁 Verifying project structure..."
mkdir -p docs
mkdir -p ios-companion-app/RayBanMetaCompanion/Sources/{App,Views,ViewModels,Services,Models,Extensions}
mkdir -p ios-companion-app/RayBanMetaCompanion/Resources
mkdir -p pocs/{voice-assistant,photo-capture,live-stream,ai-vision}
mkdir -p scripts
mkdir -p assets
echo "✅ Project structure verified"

# Check for iOS simulators
echo ""
echo "📱 Available iOS Simulators:"
xcrun simctl list devices available | grep -E "iPhone (14|15)" | head -5

echo ""
echo "=================================="
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Open ios-companion-app/RayBanMetaCompanion.xcodeproj in Xcode"
echo "2. Configure your development team in Signing & Capabilities"
echo "3. Connect your iPhone 14 Pro"
echo "4. Build and run (⌘R)"
echo ""
echo "📖 See docs/DEVELOPMENT.md for detailed instructions"
