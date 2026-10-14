# DeepSeek Peak Hours Menu Bar App

A macOS menu bar app that shows whether you're currently in DeepSeek **peak** (2× cost) or **off-peak** hours.

Peak hours (UTC):
- Monday–Friday: 01:00–04:00 and 06:00–10:00
- Weekends (Saturday–Sunday): off-peak

All other times are off-peak.

## Build & run

Requires macOS 13+ and the Swift toolchain (Xcode CLI tools).

```sh
swift build -c release
mkdir -p DeepSeekPeak.app/Contents/MacOS DeepSeekPeak.app/Contents/Resources
cp .build/arm64-apple-macosx/release/DeepSeekPeak DeepSeekPeak.app/Contents/MacOS/DeepSeekPeak
# Info.plist (LSUIElement) already included in repo if present; otherwise copy your own
open DeepSeekPeak.app
```

Or run the binary directly:

```sh
.build/arm64-apple-macosx/release/DeepSeekPeak
```

The icon turns red during peak hours and green during off-peak hours, and updates every 15 seconds. Click the item for status and the time of the next transition.