#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
rm -rf DeepSeekPeak.app
mkdir -p DeepSeekPeak.app/Contents/MacOS DeepSeekPeak.app/Contents/Resources
cp .build/arm64-apple-macosx/release/DeepSeekPeak DeepSeekPeak.app/Contents/MacOS/DeepSeekPeak
cp Info.plist DeepSeekPeak.app/Contents/Info.plist
echo "Built DeepSeekPeak.app"