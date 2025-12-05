#!/bin/bash

# macOS App Build and Test Script
# This script cleans, builds, and tests the KiroAuto macOS application

set -e  # Exit on error

echo "======================================"
echo "KiroAuto macOS App Build & Test"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory and set absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PROJECT_PATH="KiroAuto/KiroAuto.xcodeproj"
SCHEME="KiroAuto"
DERIVED_DATA_PATH="./build"

# Check if project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}✗ Error: Project not found at $PROJECT_PATH${NC}"
    exit 1
fi

# Step 1: Clean build folder
echo -e "${BLUE}[1/4] Cleaning build folder...${NC}"
rm -rf "$DERIVED_DATA_PATH"
if xcodebuild clean -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration Debug > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Build folder cleaned${NC}"
else
    echo -e "${RED}✗ Clean failed${NC}"
    exit 1
fi
echo ""

# Step 2: Build the app
echo -e "${BLUE}[2/4] Building KiroAuto app...${NC}"
# Get number of CPU cores for parallel builds
CPU_CORES=$(sysctl -n hw.ncpu)
echo "Using $CPU_CORES parallel build jobs"
BUILD_OUTPUT=$(xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -jobs "$CPU_CORES" \
    2>&1)
BUILD_STATUS=$?

# Show relevant output
echo "$BUILD_OUTPUT" | grep -E "Build Succeeded|error:|warning:" || true

if [ $BUILD_STATUS -eq 0 ]; then
    echo -e "${GREEN}✓ Build succeeded${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
echo ""

# Step 3: Run tests
echo -e "${BLUE}[3/4] Running tests...${NC}"
TEST_OUTPUT=$(xcodebuild test \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -destination 'platform=macOS' \
    2>&1)
TEST_STATUS=$?

# Show relevant output
echo "$TEST_OUTPUT" | grep -E "Test Suite|Executed|error:|warning:" || true

if [ $TEST_STATUS -eq 0 ]; then
    echo -e "${GREEN}✓ Tests passed${NC}"
else
    echo -e "${RED}✗ Tests failed${NC}"
    exit 1
fi
echo ""

# Step 4: Show build info
echo -e "${BLUE}[4/4] Build information:${NC}"
APP_PATH=$(find "$DERIVED_DATA_PATH" -name "KiroAuto.app" -type d 2>/dev/null | head -n 1)
if [ -n "$APP_PATH" ]; then
    echo "App location: $APP_PATH"
    echo "App size: $(du -sh "$APP_PATH" 2>/dev/null | cut -f1)"
    echo ""
    echo -e "${GREEN}✓ KiroAuto app is ready!${NC}"
    echo ""
    echo "To run the app:"
    echo "  open \"$APP_PATH\""
else
    echo -e "${RED}✗ App not found${NC}"
    exit 1
fi

echo ""
echo "======================================"
echo -e "${GREEN}Build and test completed successfully!${NC}"
echo "======================================"
