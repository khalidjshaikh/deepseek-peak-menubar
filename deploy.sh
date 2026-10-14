#!/bin/bash
# deploy.sh — Stop, update, and restart DeepSeekPeak

set -e

# Configuration
APP_NAME="DeepSeekPeak"
APP_PATH="/Applications/${APP_NAME}.app"
USER_APPS_DIR="${HOME}/Applications"

echo "=== DeepSeekPeak Deploy Script ==="
echo ""

# 1. Stop the running app completely
echo "Step 1: Stopping running ${APP_NAME}..."
# Kill any processes associated with the app
if pgrep -f "DeepSeekPeak" > /dev/null 2>&1; then
    pkill -f "DeepSeekPeak" || true
    echo "  → Sent termination signal to running instance."
fi
# Wait for process to fully terminate
sleep 2
# Force kill if still running
if pgrep -f "DeepSeekPeak" > /dev/null 2>&1; then
    pkill -9 -f "DeepSeekPeak" || true
    echo "  → Forced termination of remaining process."
fi
# Double-check process is gone
if pgrep -f "DeepSeekPeak" > /dev/null 2>&1; then
    echo "  ⚚ Warning: Process still running after force kill"
fi
echo "  → ${APP_NAME} stopped."

# 2. Determine destination binary path
DEST_BINARY=""
if [ -d "$APP_PATH" ]; then
    DEST_BINARY="$APP_PATH/Contents/MacOS/${APP_NAME}"
    echo "  → Found app bundle at: $APP_PATH"
elif [ -d "$USER_APPS_DIR/${APP_NAME}.app" ]; then
    DEST_BINARY="$USER_APPS_DIR/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"
    echo "  → Found app bundle at: $USER_APPS_DIR/${APP_NAME}.app"
fi

if [ -z "$DEST_BINARY" ]; then
    echo "⚠️  Could not locate existing app bundle."
    echo "   Using default path: $USER_APPS_DIR/${APP_NAME}.app"
    DEST_BINARY="$USER_APPS_DIR/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"
    mkdir -p "$USER_APPS_DIR/${APP_NAME}.app/Contents/MacOS"
    mkdir -p "$USER_APPS_DIR/${APP_NAME}.app/Contents/Resources"
fi

# 3. Build and copy new binary
echo ""
echo "Step 2: Building new binary..."
swift build -c release

# Find the released binary
RELEASE_BIN=$(find .build/out/Products/Release -name "${APP_NAME}" -type f 2>/dev/null | head -1)
if [ -z "$RELEASE_BIN" ]; then
    echo "⚠️  Could not find released binary. Looking in .build..."
    RELEASE_BIN=".build/arm64-apple-macosx/release/${APP_NAME}"
fi

echo "  → Copying new binary to $DEST_BINARY..."
cp "$RELEASE_BIN" "$DEST_BINARY"
echo "  ✅ Binary updated."

# 4. Restart the app - kill any lingering processes first
echo ""
echo "Step 3: Restarting ${APP_NAME}..."

# Ensure no lingering processes
pkill -9 -f "DeepSeekPeak" 2>/dev/null || true
sleep 1

# Launch the app
open -a "${APP_NAME}" || open "$APP_PATH"
sleep 3

echo "  → ${APP_NAME} launched."
echo ""
echo "=== Deploy complete! ==="
echo "DeepSeekPeak should now be running with the updated peak hours (v${APP_VERSION:-1.0.1})."
echo "Check the menu bar for Mon-Fri peak status and next transition times."