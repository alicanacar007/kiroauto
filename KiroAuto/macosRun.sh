#!/bin/bash

# macosRun.sh - Build and run KiroAuto macOS app without Xcode
# Usage: ./macosRun.sh

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "KiroAuto macOS Build & Run"
echo "======================================"
echo ""

# Get script directory and set absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PROJECT_PATH="KiroAuto.xcodeproj"
SCHEME="KiroAuto"
CONFIGURATION="Debug"
DERIVED_DATA_PATH="./build"

# Check if project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}✗ Error: Project not found at $PROJECT_PATH${NC}"
    exit 1
fi

# Step 1: Clean build folder
echo -e "${BLUE}[1/3] Cleaning build folder...${NC}"
rm -rf "$DERIVED_DATA_PATH"
if xcodebuild clean -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration "$CONFIGURATION" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Build folder cleaned${NC}"
else
    echo -e "${YELLOW}⚠ Clean warning (continuing anyway)${NC}"
fi
echo ""

# Step 2: Build the app
echo -e "${BLUE}[2/3] Building KiroAuto app...${NC}"
CPU_CORES=$(sysctl -n hw.ncpu)
echo "Using $CPU_CORES parallel build jobs"

BUILD_OUTPUT=$(xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -destination 'platform=macOS' \
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

# Step 3: Find and run the app
echo -e "${BLUE}[3/3] Launching app...${NC}"
APP_PATH=$(find "$DERIVED_DATA_PATH" -name "KiroAuto.app" -type d 2>/dev/null | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}✗ App not found in build directory${NC}"
    exit 1
fi

echo "App location: $APP_PATH"
echo "App size: $(du -sh "$APP_PATH" 2>/dev/null | cut -f1)"
echo ""

# Kill any existing instance
pkill -f "KiroAuto" 2>/dev/null || true
sleep 1

# Launch the app
echo -e "${GREEN}🚀 Launching KiroAuto...${NC}"
open "$APP_PATH"

echo ""
echo "======================================"
echo -e "${GREEN}✓ KiroAuto launched successfully!${NC}"
echo "======================================"

