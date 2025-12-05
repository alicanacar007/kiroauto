"""Configuration for macOS client."""
import os
from dotenv import load_dotenv

load_dotenv()

# Client configuration
MAC_ID = os.getenv("MAC_ID", "mac-01")
BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:5757")
POLL_INTERVAL = int(os.getenv("POLL_INTERVAL", "5"))  # seconds (increased from 3 to reduce CPU usage)

# Current mission (will be set at runtime)
CURRENT_MISSION_ID = None
