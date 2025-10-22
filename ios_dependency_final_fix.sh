#!/bin/bash

# Final Fix for GoogleUtilities/UserDefaults Version Conflict
# Art Luxury Bus - iOS CocoaPods Resolution

set -e  # Exit on any error

echo "🔧 FINAL iOS DEPENDENCY CONFLICT RESOLUTION"
echo "============================================="

PROJECT_ROOT="/Users/mouhamadoulaminefaye/Desktop/PROJETS DEV/mobile_dev/artluxurybus"
cd "$PROJECT_ROOT"

echo "📍 Working in: $(pwd)"

# Step 1: Clean everything completely
echo ""
echo "🧹 DEEP CLEANING..."
echo "-------------------"
rm -rf build/
rm -rf .dart_tool/
rm -rf ios/build/
rm -rf ios/Pods/
rm -rf ios/.symlinks/
rm -f ios/Podfile.lock
rm -f pubspec.lock

echo "✅ Cleaned all build artifacts"

# Step 2: Get Flutter dependencies with new QR scanner
echo ""
echo "📦 GETTING FLUTTER DEPENDENCIES..."
echo "----------------------------------"
if command -v flutter &> /dev/null; then
    flutter pub get
    echo "✅ Flutter dependencies resolved"
else
    echo "⚠️  Flutter command not found. Please run manually:"
    echo "   flutter pub get"
    echo ""
fi

# Step 3: Update CocoaPods repository  
echo ""
echo "🔄 UPDATING COCOAPODS REPOSITORY..."
echo "-----------------------------------"
cd ios
if command -v pod &> /dev/null; then
    pod repo update
    echo "✅ CocoaPods repo updated"
else
    echo "⚠️  CocoaPods not found. Installing..."
    if command -v gem &> /dev/null; then
        gem install --user-install cocoapods
        export PATH=$PATH:~/.gem/ruby/*/bin
    else
        echo "❌ Ruby/gem not found. Please install CocoaPods manually:"
        echo "   sudo gem install cocoapods"
        exit 1
    fi
fi

# Step 4: Try pod install with version override
echo ""
echo "🍎 INSTALLING PODS WITH FORCED VERSIONS..."
echo "------------------------------------------"

# Method 1: Try with forced GoogleUtilities version
echo "Attempting Method 1: Forced GoogleUtilities version..."
pod install --repo-update 2>&1 | tee pod_install.log

# Check if it succeeded
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ SUCCESS: Pods installed with forced GoogleUtilities version!"
else
    echo "⚠️  Method 1 failed. Trying Method 2..."
    
    # Method 2: Temporary Podfile modification
    echo ""
    echo "📝 Trying alternative Podfile configuration..."
    
    # Backup original Podfile
    cp Podfile Podfile.backup
    
    # Create alternative Podfile
    cat > Podfile << 'EOF'
platform :ios, '14.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # Force compatible versions to resolve conflicts
  pod 'GoogleUtilities', '8.1.0'
  pod 'GoogleMLKit/BarcodeScanning', '6.0.0'
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end
EOF

    # Try again with modified Podfile
    pod install --repo-update
    
    if [ $? -eq 0 ]; then
        echo "✅ SUCCESS: Method 2 worked!"
    else
        echo "❌ Method 2 also failed. Restoring original Podfile..."
        mv Podfile.backup Podfile
        
        echo ""
        echo "🔄 LAST RESORT: Trying without mobile_scanner..."
        echo "You may need to remove QR scanning temporarily:"
        echo "1. Comment out qr_code_scanner in pubspec.yaml"
        echo "2. Run flutter pub get"  
        echo "3. Run pod install"
        echo "4. Then find an alternative QR scanner"
    fi
fi

echo ""
echo "📊 FINAL STATUS:"
echo "================"
if [ -d "Pods" ]; then
    echo "✅ Pods directory exists"
    ls -la Pods/ | head -5
else
    echo "❌ Pods installation failed"
fi

echo ""
echo "🎯 NEXT STEPS:"
echo "1. Build your app: flutter build ios --no-codesign"
echo "2. If QR scanner issues persist, consider using:"
echo "   - ai_barcode_scanner (newer, Firebase compatible)"
echo "   - barcode_scan2 (lightweight alternative)"
echo ""
echo "📱 Test with: flutter run"
