#!/bin/sh
set -e
brew install xcodegen
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate
xcodebuild -resolvePackageDependencies -project Synced.xcodeproj -scheme Synced
