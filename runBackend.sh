#!/bin/bash

# runBackend.sh - Script to start the FastAPI backend server
# Usage: ./runBackend.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKEND_DIR="${SCRIPT_DIR}/backend"

echo -e "${BLUE}🚀 Starting AutoIDE Controller Backend...${NC}\n"

# Check if backend directory exists
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}❌ Error: Backend directory not found at $BACKEND_DIR${NC}"
    exit 1
fi

# Change to backend directory
cd "$BACKEND_DIR"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}⚠️  Virtual environment not found. Creating one...${NC}"
    python3 -m venv venv
    echo -e "${GREEN}✅ Virtual environment created${NC}\n"
fi

# Activate virtual environment
echo -e "${BLUE}📦 Activating virtual environment...${NC}"
source venv/bin/activate

# Check if requirements are installed
if ! python -c "import fastapi" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Dependencies not installed. Installing requirements...${NC}"
    pip install -q --upgrade pip
    pip install -q -r requirements.txt
    echo -e "${GREEN}✅ Dependencies installed${NC}\n"
fi

# Check for .env file (optional, just warn if missing)
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  Warning: .env file not found.${NC}"
    echo -e "${YELLOW}   The app will work but GEMINI_API_KEY may not be set.${NC}"
    echo -e "${YELLOW}   Create a .env file with GEMINI_API_KEY=your_key if needed.${NC}\n"
fi

# Display server info
echo -e "${GREEN}✅ Backend ready!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   Server starting on: http://localhost:5757${NC}"
echo -e "${GREEN}   API Docs: http://localhost:5757/docs${NC}"
echo -e "${GREEN}   ReDoc: http://localhost:5757/redoc${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}\n"

# Run the server with uvicorn
# --reload enables auto-reload on code changes
# --host 0.0.0.0 allows connections from other devices on the network
# --port 5757 uses the configured port
uvicorn app.main:app --host 0.0.0.0 --port 5757 --reload



