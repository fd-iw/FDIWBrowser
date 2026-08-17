#!/usr/bin/env bash
# Build FDIWBrowser into an unsigned .ipa. macOS + Xcode required.
set -euo pipefail

command -v xcodegen >/dev/null || { echo "Installing XcodeGen..."; brew install xcodegen; }

xcodegen generate

rm -rf build
xcodebuild \
  -project FDIWBrowser.xcodeproj \
  -scheme FDIWBrowser \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath build/FDIWBrowser.xcarchive \
  archive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_BITCODE=NO

mkdir -p build/Payload
cp -R build/FDIWBrowser.xcarchive/Products/Applications/FDIWBrowser.app build/Payload/
(cd build && zip -qry FDIWBrowser-unsigned.ipa Payload)

echo
echo "Done -> build/FDIWBrowser-unsigned.ipa"
echo "Sign it with Sideloadly / AltStore, or open the .xcodeproj and run to your device."
