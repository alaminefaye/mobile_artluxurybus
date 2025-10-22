#!/bin/bash

# Fix iOS CocoaPods dependency conflict for Art Luxury Bus
# This script resolves GoogleUtilities/UserDefaults version conflict

echo "🔧 Fixing iOS CocoaPods dependency conflict..."
echo "================================================"

# Navigate to project root
PROJECT_ROOT="/Users/mouhamadoulaminefaye/Desktop/PROJETS DEV/mobile_dev/artluxurybus"
cd "$PROJECT_ROOT"

echo "📍 Current directory: $(pwd)"

# Step 1: Clean Flutter build cache
echo "🧹 Cleaning Flutter build cache..."
if command -v flutter &> /dev/null; then
    flutter clean
else
    echo "⚠️  Flutter not found in PATH. Trying alternative methods..."
    rm -rf build/
    rm -rf ios/build/
    rm -rf .dart_tool/
fi

# Step 2: Remove iOS build artifacts
echo "🗑️  Removing iOS build artifacts..."
cd ios
rm -rf build/
rm -rf Pods/
rm -rf .symlinks/
rm -f Podfile.lock

# Step 3: Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
cd "$PROJECT_ROOT"
if command -v flutter &> /dev/null; then
    flutter pub get
else
    echo "⚠️  Flutter not found. Please run 'flutter pub get' manually after adding Flutter to PATH."
fi

# Step 4: iOS pod install (with CocoaPods available)
echo "🍎 Installing iOS pods..."
cd ios
if command -v pod &> /dev/null; then
    # Update CocoaPods repo to get latest specs
    echo "🔄 Updating CocoaPods repository..."
    pod repo update
    
    # Install with updated dependencies
    echo "⬇️  Installing pods with updated dependencies..."
    pod install --repo-update
else
    echo "⚠️  CocoaPods not found. Please install CocoaPods first:"
    echo "   sudo gem install cocoapods"
    echo "   Then run: pod install --repo-update"
fi

echo ""
echo "✅ iOS dependency fix completed!"
echo ""
echo "📋 Next steps:"
echo "1. If CocoaPods is not installed, install it with:"
echo "   sudo gem install cocoapods"
echo "2. Navigate to ios/ directory: cd ios"  
echo "3. Run: pod install --repo-update"
echo "4. Build your Flutter app: flutter build ios"
echo ""
echo "💡 If issues persist, try:"
echo "   - Delete ios/Podfile.lock and run pod install again"
echo "   - Update mobile_scanner to the latest version"
echo "   - Check iOS deployment target is 14.0+"
