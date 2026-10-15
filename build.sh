#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)"
rm -rf DeepSeekPeak.app
mkdir -p DeepSeekPeak.app/Contents/MacOS DeepSeekPeak.app/Contents/Resources
cp "$BIN_PATH/DeepSeekPeak" DeepSeekPeak.app/Contents/MacOS/DeepSeekPeak
cp Info.plist DeepSeekPeak.app/Contents/Info.plist
echo "Built DeepSeekPeak.app"