#!/bin/sh
set -e
brew install xcodegen
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate
mkdir -p Synced.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
cp Package.resolved Synced.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
