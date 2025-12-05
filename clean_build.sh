#!/bin/bash

# Quick Build Cache Cleaner
# This script cleans Xcode build caches to improve build performance

set -e

echo "======================================"
echo "Xcode Build Cache Cleaner"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
MODULE_CACHE="$DERIVED_DATA/ModuleCache.noindex"
BUILD_CACHE="$HOME/Library/Caches/com.apple.dt.Xcode"
PROJECT_BUILD="./build"

# Function to get directory size
get_size() {
    if [ -d "$1" ]; then
        du -sh "$1" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

echo -e "${BLUE}Current cache sizes:${NC}"
echo "  Derived Data: $(get_size "$DERIVED_DATA")"
echo "  Module Cache: $(get_size "$MODULE_CACHE")"
echo "  Build Cache: $(get_size "$BUILD_CACHE")"
echo "  Project Build: $(get_size "$PROJECT_BUILD")"
echo ""

# Ask for confirmation
read -p "Do you want to clean all build caches? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Cleaning caches...${NC}"

# Clean project build folder
if [ -d "$PROJECT_BUILD" ]; then
    echo "  Cleaning project build folder..."
    rm -rf "$PROJECT_BUILD"
    echo -e "  ${GREEN}✓ Project build cleaned${NC}"
fi

# Clean module cache
if [ -d "$MODULE_CACHE" ]; then
    echo "  Cleaning module cache..."
    rm -rf "$MODULE_CACHE"
    echo -e "  ${GREEN}✓ Module cache cleaned${NC}"
fi

# Clean build cache (optional, more aggressive)
read -p "Clean Xcode build cache (more aggressive)? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "$BUILD_CACHE" ]; then
        echo "  Cleaning Xcode build cache..."
        rm -rf "$BUILD_CACHE"
        echo -e "  ${GREEN}✓ Build cache cleaned${NC}"
    fi
fi

# Clean derived data (most aggressive)
read -p "Clean ALL derived data (will require full rebuild)? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "$DERIVED_DATA" ]; then
        echo "  Cleaning all derived data..."
        rm -rf "$DERIVED_DATA"/*
        echo -e "  ${GREEN}✓ Derived data cleaned${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✓ Cleanup completed!${NC}"
echo ""
echo "Next build will be slower (full rebuild), but subsequent builds will be faster."
echo ""



