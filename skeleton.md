# Project Skeleton Structure

## Complete Folder Structure

```
auto-ide-controller/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py              # FastAPI app entry point
│   │   ├── models.py            # Pydantic models (MissionIn, EventIn, etc.)
│   │   ├── db.py                # SQLite database setup & helpers
│   │   ├── ai_planner.py        # Gemini API integration for planning
│   │   └── routes.py            # API endpoints (missions, events, steps)
│   ├── requirements.txt
│   ├── .env                     # GEMINI_API_KEY=your_key_here
│   └── db.sqlite                # SQLite database (created automatically)
│
├── mac-client/
│   ├── main.py                  # Entry point - starts all agents
│   ├── config.py                # Configuration (mac_id, backend_url, etc.)
│   ├── agents/
│   │   ├── __init__.py
│   │   ├── mission_controller.py   # Main orchestrator - polls backend
│   │   ├── step_executor.py        # Executes step actions sequentially
│   │   ├── marker_watcher.py       # Watches files for //C markers (parallel)
│   │   ├── kiro_automator.py       # Kiro-specific automation (AI chat)
│   │   └── screenshot_analyzer.py  # AI vision for screenshot analysis
│   ├── actions/
│   │   ├── __init__.py
│   │   ├── app_actions.py          # open_app, focus_app, check_if_open
│   │   ├── input_actions.py        # click, type, keyboard shortcuts
│   │   ├── file_actions.py         # edit_file, apply_patch, git operations
│   │   └── screenshot_actions.py   # take_screenshot, encode_base64
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── http_client.py          # HTTP requests to backend
│   │   └── logger.py               # Logging setup
│   ├── requirements.txt
│   └── README.md
│
├── ios-client/                   # Optional - for demo
│   ├── AutoIDEPhone.xcodeproj
│   └── Sources/
│       ├── ContentView.swift      # Mission submission form
│       └── MissionView.swift      # Mission status & progress
│
├── docs/
│   ├── demo_script.md
│   ├── skeleton.md               # This file
│   ├── agentsArc.md              # Agents architecture
│   ├── phase.md                  # Development phases
│   └── testWorkFlows.md          # Test workflows
│
├── .gitignore
└── README.md                     # Main project README
```

## File Templates

### backend/app/main.py
```python
from fastapi import FastAPI
from app.routes import router
from app.db import init_db

app = FastAPI(title="AutoIDE Controller")
app.include_router(router)

init_db()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5757)
```

### backend/app/models.py
```python
from pydantic import BaseModel
from typing import Optional, List

class MissionIn(BaseModel):
    user: str
    prompt: str
    repo_path: str
    mac_id: Optional[str] = "mac-01"

class EventIn(BaseModel):
    mac_id: str
    step_id: str
    status: str  # "running", "completed", "failed", "stalled"
    stdout: Optional[str] = ""
    stderr: Optional[str] = ""
    screenshots: Optional[List[str]] = None
    found_markers: Optional[List[str]] = None
```

### mac-client/main.py
```python
import threading
from agents.mission_controller import MissionController
from agents.marker_watcher import MarkerWatcher
from config import MAC_ID, BACKEND_URL

def main():
    # Start Mission Controller (main loop)
    controller = MissionController(mac_id=MAC_ID, backend_url=BACKEND_URL)
    
    # Start Marker Watcher in background thread
    watcher = MarkerWatcher(backend_url=BACKEND_URL)
    watcher_thread = threading.Thread(target=watcher.start, daemon=True)
    watcher_thread.start()
    
    # Run main controller loop
    controller.run()

if __name__ == "__main__":
    main()
```

### mac-client/config.py
```python
import os
from dotenv import load_dotenv

load_dotenv()

MAC_ID = os.getenv("MAC_ID", "mac-01")
BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:5757")
POLL_INTERVAL = int(os.getenv("POLL_INTERVAL", "3"))  # seconds
REPO_PATH = os.getenv("REPO_PATH", "")  # Set per mission
```

### mac-client/agents/mission_controller.py
```python
import time
import requests
from utils.http_client import HTTPClient
from agents.step_executor import StepExecutor

class MissionController:
    def __init__(self, mac_id, backend_url):
        self.mac_id = mac_id
        self.backend_url = backend_url
        self.http_client = HTTPClient(backend_url)
        self.step_executor = StepExecutor(mac_id, backend_url)
        self.current_mission_id = None
    
    def get_next_step(self):
        if not self.current_mission_id:
            return None
        return self.http_client.get_next_step(self.current_mission_id, self.mac_id)
    
    def run(self):
        while True:
            step_data = self.get_next_step()
            if step_data and step_data.get("step"):
                step = step_data["step"]
                self.step_executor.execute(step, self.current_mission_id)
            time.sleep(3)
```

## Database Schema

### missions table
```sql
CREATE TABLE missions (
    id TEXT PRIMARY KEY,
    user TEXT,
    prompt TEXT,
    repo_path TEXT,
    mac_id TEXT,
    status TEXT,  -- "pending", "running", "done", "failed"
    plan_json TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### steps table (optional - can derive from plan_json)
```sql
CREATE TABLE steps (
    id TEXT PRIMARY KEY,
    mission_id TEXT,
    step_id TEXT,
    title TEXT,
    actions_json TEXT,
    status TEXT,  -- "pending", "running", "completed", "failed"
    expect_marker TEXT,
    FOREIGN KEY (mission_id) REFERENCES missions(id)
);
```

### events table
```sql
CREATE TABLE events (
    id TEXT PRIMARY KEY,
    mission_id TEXT,
    step_id TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payload TEXT,  -- JSON with status, stdout, stderr, screenshots, markers
    FOREIGN KEY (mission_id) REFERENCES missions(id)
);
```

## Dependencies

### backend/requirements.txt
```
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
python-dotenv>=1.0.0
httpx>=0.25.0
pydantic>=2.5.0
google-generativeai>=0.3.0  # Gemini API
```

### mac-client/requirements.txt
```
pyautogui>=0.9.54
macuiauto>=1.0.0
watchdog>=3.0.0
pillow>=10.0.0
requests>=2.31.0
python-dotenv>=1.0.0
google-generativeai>=0.3.0  # Gemini Vision API
```

## Environment Variables

### backend/.env
```
GEMINI_API_KEY=your_gemini_api_key_here
```

### mac-client/.env (optional)
```
MAC_ID=mac-01
BACKEND_URL=http://localhost:5757
POLL_INTERVAL=3
```

## Initial Setup Commands

```bash
# Backend setup
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env  # Add your GEMINI_API_KEY
uvicorn app.main:app --port 5757 --reload

# macOS client setup
cd mac-client
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py
```

