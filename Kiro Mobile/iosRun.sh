#!/bin/bash

# iosRun.sh - Build and run Kiro Mobile iOS app on simulator without Xcode
# Usage: ./iosRun.sh [simulator-name]

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "Kiro Mobile iOS Build & Run"
echo "======================================"
echo ""

# Get script directory and set absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PROJECT_PATH="Kiro Mobile.xcodeproj"
SCHEME="Kiro Mobile"
CONFIGURATION="Debug"
DERIVED_DATA_PATH="./build"
BUNDLE_ID="alicanacar.Kiro-Mobile"

# Check if project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}✗ Error: Project not found at $PROJECT_PATH${NC}"
    exit 1
fi

# Step 1: Find or create iOS Simulator
echo -e "${BLUE}[1/4] Finding iOS Simulator...${NC}"

# If simulator name provided as argument, use it
if [ -n "$1" ]; then
    SIMULATOR_NAME="$1"
    # Search in all devices (not just available)
    SIMULATOR_LINE=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep -i "iPhone" | head -n 1)
    SIMULATOR_UDID=$(echo "$SIMULATOR_LINE" | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}' | head -n 1)
else
    # First try to find a booted iPhone simulator
    SIMULATOR_LINE=$(xcrun simctl list devices | grep -i "iPhone" | grep "Booted" | head -n 1)
    if [ -z "$SIMULATOR_LINE" ]; then
        # If none booted, find first shutdown iPhone simulator
        SIMULATOR_LINE=$(xcrun simctl list devices | grep -i "iPhone" | grep "Shutdown" | head -n 1)
    fi
    SIMULATOR_UDID=$(echo "$SIMULATOR_LINE" | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}' | head -n 1)
    SIMULATOR_NAME=$(echo "$SIMULATOR_LINE" | sed 's/.*(\([^)]*\)).*/\1/' | awk '{print $1, $2, $3}')
fi

if [ -z "$SIMULATOR_UDID" ]; then
    echo -e "${RED}✗ No iOS simulator found${NC}"
    echo "Available simulators:"
    xcrun simctl list devices | grep -i "iPhone"
    exit 1
fi

echo "Using simulator: $SIMULATOR_NAME ($SIMULATOR_UDID)"

# Boot the simulator if not already booted
SIMULATOR_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_UDID" | grep -oE '\([^)]+\)' | tr -d '()')
if [ "$SIMULATOR_STATE" != "Booted" ]; then
    echo "Booting simulator..."
    xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
    sleep 3
fi

# Open Simulator app
open -a Simulator
sleep 2

echo -e "${GREEN}✓ Simulator ready${NC}"
echo ""

# Step 2: Clean build folder
echo -e "${BLUE}[2/4] Cleaning build folder...${NC}"
rm -rf "$DERIVED_DATA_PATH"
if xcodebuild clean -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration "$CONFIGURATION" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Build folder cleaned${NC}"
else
    echo -e "${YELLOW}⚠ Clean warning (continuing anyway)${NC}"
fi
echo ""

# Step 3: Build the app for simulator
echo -e "${BLUE}[3/4] Building Kiro Mobile app for iOS Simulator...${NC}"
CPU_CORES=$(sysctl -n hw.ncpu)
echo "Using $CPU_CORES parallel build jobs"

BUILD_OUTPUT=$(xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -destination "id=$SIMULATOR_UDID" \
    -sdk iphonesimulator \
    -jobs "$CPU_CORES" \
    2>&1)
BUILD_STATUS=$?

# Show relevant output
echo "$BUILD_OUTPUT" | grep -E "Build Succeeded|error:|warning:" || true

if [ $BUILD_STATUS -eq 0 ]; then
    echo -e "${GREEN}✓ Build succeeded${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    echo "$BUILD_OUTPUT" | tail -20
    exit 1
fi
echo ""

# Step 4: Install and launch the app
echo -e "${BLUE}[4/4] Installing and launching app...${NC}"

# Find the built app
APP_PATH=$(find "$DERIVED_DATA_PATH" -name "Kiro Mobile.app" -type d 2>/dev/null | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}✗ App not found in build directory${NC}"
    exit 1
fi

echo "App location: $APP_PATH"
echo "App size: $(du -sh "$APP_PATH" 2>/dev/null | cut -f1)"
echo ""

# Uninstall existing app if present
xcrun simctl uninstall "$SIMULATOR_UDID" "$BUNDLE_ID" 2>/dev/null || true

# Install the app
echo "Installing app on simulator..."
xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"

# Launch the app
echo -e "${GREEN}🚀 Launching Kiro Mobile...${NC}"
xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID"

echo ""
echo "======================================"
echo -e "${GREEN}✓ Kiro Mobile launched successfully!${NC}"
echo "======================================"
echo ""
echo "Simulator: $SIMULATOR_NAME"
echo "Bundle ID: $BUNDLE_ID"

