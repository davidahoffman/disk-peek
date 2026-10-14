#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
app_path="build/Xcode/Build/Products/Release/Disk Peek.app"
mkdir -p build
xcrun swiftc -swift-version 6 -O -parse-as-library Storage.swift StorageTests.swift -o build/StorageTests
build/StorageTests
xcrun swiftc -swift-version 6 -O -parse-as-library Storage.swift SharedFiles.swift \
  LargestFileScanner.swift SharedFilesTests.swift -o build/SharedFilesTests
build/SharedFilesTests
xcodegen generate
xcodebuild -project DiskPeek.xcodeproj -scheme DiskPeek -configuration Release \
  -derivedDataPath build/Xcode -destination 'platform=macOS,arch=arm64' build
codesign --verify --deep --strict "$app_path"
plutil -lint "$app_path/Contents/Info.plist" "$app_path/Contents/PlugIns/DiskPeekWidget.appex/Contents/Info.plist"
printf 'Built: %s/%s\n' "$PWD" "$app_path"
