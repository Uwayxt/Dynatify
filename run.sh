#!/bin/bash
# Build & Launch Dynatify • by @uwayxt
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$DIR/build/Dynatify.app"

echo "Building Dynatify..."
cd "$DIR/MelodyIsland"
xcodebuild -project MelodyIsland.xcodeproj -scheme Dynatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO

mkdir -p "$DIR/build"
cp -R ~/Library/Developer/Xcode/DerivedData/MelodyIsland-*/Build/Products/Debug/Dynatify.app "$DIR/build/"

echo "Launching Dynatify ($APP_PATH)..."
open "$APP_PATH"
