Overview (one-line)
User (iOS) → FastAPI backend (port 5757, Gemini in .env) → macOS client (polling HTTP) → automation (Accessibility/CGEvent/Vision / shell) → backend polls / stores progress → iOS polls backend for status.
Tech stack (free / minimal)
Backend: Python 3.11+, FastAPI, Uvicorn, python-dotenv, httpx, APScheduler (optional) or simple threading.
Data storage: SQLite (via sqlite3 or SQLModel) — lightweight and local.
AI: Gemini API—key stored in .env (you provide).
macOS client: Python 3.11+ — uses pyautogui (mouse/keyboard), macuiauto/pyatomac (Accessibility API for UI elements), watchdog (file watching), PIL (screenshots), subprocess (shell commands). Runs as background service with parallel agents architecture.
iOS client (demo): SwiftUI — simple UI to submit mission & poll status.
All communication over plain HTTP (no sockets). Backend listens at http://localhost:5757.
High-level components & responsibilities
Backend (FastAPI): accept missions, call Gemini for plan, store mission + steps in SQLite, serve steps to mac client, accept step events (progress), provide mission status to iOS.
macOS client: Parallel agents architecture — Mission Controller orchestrates, Step Executor runs actions, Marker Watcher monitors files (parallel), Kiro Automator handles Kiro-specific AI interactions, Screenshot Analyzer uses AI vision for file detection. Polls backend for steps, executes actions (open app, click, type, run command, take screenshot, prompt Kiro AI), reports results back to backend.
iOS demo app: minimal UI to submit mission (text + local repo path), poll status, show step logs/screenshots.
Folder structure (monorepo)
auto-ide-controller/
├─ backend/
│  ├─ app/
│  │  ├─ main.py
│  │  ├─ models.py
│  │  ├─ db.py
│  │  ├─ ai_planner.py
│  │  └─ routes.py
│  ├─ requirements.txt
│  └─ .env
├─ mac-client/
│  ├─ main.py                    # Entry point
│  ├─ config.py                  # Configuration
│  ├─ agents/
│  │  ├─ __init__.py
│  │  ├─ mission_controller.py   # Main orchestrator
│  │  ├─ step_executor.py        # Executes steps
│  │  ├─ marker_watcher.py       # Watches files for //C markers
│  │  ├─ kiro_automator.py       # Kiro-specific automation
│  │  └─ screenshot_analyzer.py  # AI vision for screenshots
│  ├─ actions/
│  │  ├─ __init__.py
│  │  ├─ app_actions.py          # Open app, focus
│  │  ├─ input_actions.py        # Mouse, keyboard, shortcuts
│  │  ├─ file_actions.py         # File operations, git
│  │  └─ screenshot_actions.py   # Screenshot capture
│  ├─ utils/
│  │  ├─ __init__.py
│  │  ├─ http_client.py          # Backend communication
│  │  └─ logger.py               # Logging
│  ├─ requirements.txt
│  └─ README.md
├─ ios-client/
│  ├─ AutoIDEPhone.xcodeproj
│  └─ Sources/
├─ docs/
│  └─ demo_script.md
└─ README.md
Minimal backend API (FastAPI) — endpoints & schemas
Run server on http://localhost:5757.
Main endpoints
POST /missions — submit a new mission (from iOS)
GET /missions/{mission_id} — get mission metadata & status
GET /missions/{mission_id}/next_step?mac_id=<mac> — mac client polls for next step
POST /missions/{mission_id}/events — mac client posts step result events (success/fail, screenshots, logs)
GET /missions/{mission_id}/steps — view full plan (for UI)
POST /missions/{mission_id}/retry_step — request AI replan for failing step (optional)
JSON data shapes
Submit mission (client → backend)
POST /missions
{
  "user":"alice",
  "prompt":"Create a Next.js ecommerce skeleton with Stripe product page",
  "repo_path":"/Users/alice/Projects/shop",
  "mac_id":"mac-01"   // identify which mac will run mission
}
Backend plan (AI → backend stored)
{
  "mission_id":"m-001",
  "plan":[
    {
      "step_id":"s-1",
      "title":"Open Kiro and open project",
      "actions":[
        {"type":"open_app","app":"Kiro"},
        {"type":"open_project","path":"/Users/alice/Projects/shop"},
        {"type":"screenshot"}
      ],
      "expect_marker":"C-1001"  // optional marker to detect
    },
    {
      "step_id":"s-2",
      "title":"Create products page",
      "actions":[
        {"type":"edit_file","file":"src/pages/product.tsx","patch":"..."},
        {"type":"git_commit","message":"Add product page"},
        {"type":"run_test","cmd":"npm test"}
      ],
      "expect_marker":"C-1002"
    }
  ]
}
Step event (mac → backend)
POST /missions/{mission_id}/events
{
  "mac_id":"mac-01",
  "step_id":"s-1",
  "status":"completed",       // "running", "completed", "failed"
  "stdout":"npm test output...",
  "stderr":"",
  "screenshots":["data:image/png;base64,..."],
  "found_markers":["C-1001"]
}
Backend design details
Data model (simple)
missions: id, user, prompt, repo_path, status (pending, running, done, failed), created_at
steps: id, mission_id, step_id, title, actions JSON, status, expect_marker
events/logs: mission_id, step_id, timestamp, payload JSON
Use SQLite (sqlmodel or sqlite3) for simplicity.
AI planner (ai_planner.py)
On mission creation, call Gemini with a structured prompt:
Input: user prompt + repo_path + constraints (use Kiro markers etc).
Output: JSON plan (array of steps and actions). Validate JSON with strict schema.
Keep prompts small and instruct Gemini to output only JSON.
Worker / Scheduler
No sockets: mac client polls GET /missions/{id}/next_step?mac_id=mac-01. Backend returns the next step for that mac. If none, return {"step": null}.
Backend marks step running when returned. If step not completed in X minutes, mark failed or allow client to re-poll.
Simple concurrency
Keep one active step per mac. Use SQLite row locks or an in-memory map to prevent multiple assignment.
macOS client design (Python, parallel agents, minimal permissions)
Language: Python 3.11+ (no Xcode needed)
Architecture: Parallel agents running in separate threads:
- Mission Controller: Main orchestrator, polls backend every 3-5s
- Step Executor: Executes step actions sequentially
- Marker Watcher: Watches files for //C markers in parallel (background thread)
- Kiro Automator: Handles Kiro AI chat interactions
- Screenshot Analyzer: Uses AI vision to analyze screenshots and detect file lists

Poll every N seconds (e.g., 3–5s) to GET /missions/{mission}/next_step?mac_id=mac-01
On new step:
- Step Executor executes each action in order
- Marker Watcher runs in parallel, monitoring files
- Kiro Automator handles Kiro-specific actions (AI chat)
- Report progress to /missions/{mission}/events after step finishes or fails

No sockets or JWT; for local demo we can pass mac_id param only.

Core capabilities to implement (Python libraries)
- Open app: subprocess.run(["open", "-a", "Kiro"]) or pyautogui
- Bring to front: pyautogui.getWindowsWithTitle() + activate
- Take screenshot: pyautogui.screenshot() → PIL → base64
- Simulate keyboard/mouse: pyautogui.click(), pyautogui.typewrite(), pyautogui.hotkey()
- UI element access: macuiauto/pyatomac for Accessibility API (find buttons, inputs by text)
- Run shell commands: subprocess.run() for npm test, git commands
- File watching: watchdog library for FSEvents-based file monitoring
- Marker detection: on file change, scan files for regex //C \d+ (simple text search)
- Kiro AI interaction: Use Accessibility API to find AI chat input, type prompt, submit
- Screenshot + AI: Send screenshot to Gemini Vision API, extract file list
- Report: POST event JSON to backend via requests library

Example mac client architecture (Python)
```python
# Parallel agents running
mission_controller = MissionController(mac_id="mac-01")
marker_watcher = MarkerWatcher(repo_path, callback=on_marker_found)
step_executor = StepExecutor()

# Main loop
while True:
    step = mission_controller.get_next_step()
    if step:
        step_executor.execute(step)
        mission_controller.report_event(step, status="completed")
    time.sleep(3)
```
Action types to support (initial)
open_app — open & focus an application (subprocess or pyautogui)
open_project — simulate keyboard to open project in Kiro (Cmd+O or Accessibility API)
click — click at (x,y) or click on AX element text (pyautogui or macuiauto)
type — type a string (pyautogui.typewrite())
screenshot — take screenshot and upload (pyautogui.screenshot())
run_command — run shell command in project dir (subprocess)
wait_for_marker — watch files until expected //C N appears or timeout (watchdog + regex)
apply_patch — write a given patch to file(s) and git commit (file I/O + subprocess)
prompt_kiro_ai — interact with Kiro's AI chat (Accessibility API to find input, type, submit)
analyze_screenshot — send screenshot to AI vision API, extract file list or status
Start with open_app, screenshot, run_command, wait_for_marker, then add prompt_kiro_ai.
iOS client design (demo only)
SwiftUI app with 2 screens:
Submit: text field for mission prompt, text field for repo_path (local path on mac), mac_id selection, submit button → calls POST /missions.
Mission: polls GET /missions/{mission_id} every 2–5s to show status, step list, and screenshots.
Polling is fine for demo.
Phase-by-phase plan (simple, local-demo friendly)
Phase 0 — Setup & skeleton (1–2 days)
Goal: Local FastAPI running, mac client can fetch next_step + POST event, iOS can submit mission.
Create repo skeleton (folders)
Backend: FastAPI app with SQLite, endpoints POST /missions, GET /missions/{id}, GET /missions/{id}/next_step, POST /missions/{id}/events.
mac client: connect to backend → GET returns null step initially → POST test event → backend stores it.
iOS: form to POST sample mission.
Demo target: Submit mission on iOS → mission appears in backend → mac client polls and receives null → you can POST an event to backend and see it in DB.
Phase 1 — AI planner + simple static plan (1–2 days)
Goal: Connect Gemini (use .env GEMINI_API_KEY). On mission submit, call AI to return a structured plan JSON. For early tests you can use a static template plan and skip Gemini until stable.
Implement ai_planner.py with plan_from_prompt(prompt, repo_path): return JSON plan. Start with fixed sample plan then switch to Gemini.
Backend stores plan steps in SQLite.
Demo target: Submit mission → backend stores plan (2–3 steps) → GET /missions/{id}/steps shows plan.
Phase 2 — mac client executes simple actions (2–4 days)
Goal: mac client can:
Open Kiro (subprocess or pyautogui)
Open project folder in Kiro (keyboard shortcut Cmd+O or Accessibility API)
Take and upload screenshot (pyautogui.screenshot())
Run npm test in repo folder and return output (subprocess)
Detect a marker added manually (//C 1001) via file watch (watchdog)
Implement parallel Marker Watcher agent
Demo target: Manually add //C 1001 to a file → Marker Watcher detects it → posts event → backend moves to next step.
Phase 3 — automated edition & test loop (3–6 days)
Goal: Backend+AI + mac client implement edit/test/fix loop:
For a failing test, backend calls Gemini to produce a suggested code patch (structured response: file path + new content or unified diff).
Backend sends apply_patch action to mac client.
Mac client writes files, commits, runs tests again.
On success, mac writes marker //C N to indicate step completion; reports back.
Add Kiro AI integration: Prompt Kiro AI with mission, extract file list from response.
Add Screenshot Analyzer: Use Gemini Vision API to analyze screenshots and detect file lists.
Demo target: A simple failing unit test; AI suggests a small fix; client applies it; tests pass; mission proceeds. Or: Prompt Kiro AI → Get file list → Edit files → Test → Pass.
Phase 4 — Watchdog & screenshot-ask (2–4 days)
Goal: Implement a watchdog for stuck steps:
If a step runs longer than threshold, mac captures screenshot + last logs → POST to /events with status:"stalled".
Backend gathers context + calls Gemini for step guidance or formats a clarifying question for user on iOS.
Demo target: Trigger stuck state (sleep in action) → watchod captures screenshot → AI returns suggestion; iOS displays suggestion.
Phase 5 — UX polish, demo video & docs (2–3 days)
Goal: Make clean demo:
iOS shows mission progress, screenshots, and success message
Backend logs and show step timeline
Mac client UI for manual override (pause/resume)
Prepare 2–3 minute demo script and record video
Minimal FastAPI skeleton (paste & run)
Create backend/app/main.py. Below is a minimal example to get you started — it uses SQLite (file db.sqlite) and a very tiny in-memory plan generator fallback. Put your Gemini key in .env as GEMINI_API_KEY.
Important: This is a minimal demo skeleton to run locally — not production hardened.
# backend/app/main.py
import os
import uuid
import json
import sqlite3
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv
from typing import Optional

load_dotenv()
GEMINI_KEY = os.getenv("GEMINI_API_KEY", "")

DB = "db.sqlite"
PORT = 5757

app = FastAPI(title="AutoIDE Controller (demo)")

# --- DB helpers (very simple)
def init_db():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("""CREATE TABLE IF NOT EXISTS missions (
                    id TEXT PRIMARY KEY, user TEXT, prompt TEXT, repo_path TEXT,
                    mac_id TEXT, status TEXT, plan_json TEXT
                )""")
    c.execute("""CREATE TABLE IF NOT EXISTS events (
                    id TEXT PRIMARY KEY, mission_id TEXT, step_id TEXT, payload TEXT
                )""")
    conn.commit()
    conn.close()

init_db()

# --- Pydantic models
class MissionIn(BaseModel):
    user: str
    prompt: str
    repo_path: str
    mac_id: Optional[str] = "mac-01"

class EventIn(BaseModel):
    mac_id: str
    step_id: str
    status: str
    stdout: Optional[str] = ""
    stderr: Optional[str] = ""
    screenshots: Optional[list] = None
    found_markers: Optional[list] = None

# --- Simple planner (fallback static plan)
def simple_plan_for(prompt, repo_path):
    # In production, call Gemini here and parse JSON. For demo return sample plan
    pid = str(uuid.uuid4())[:8]
    return {
        "mission_id": pid,
        "plan": [
            {
                "step_id": "s-1",
                "title": "Open Kiro & project",
                "actions": [
                    {"type":"open_app","app":"Kiro"},
                    {"type":"open_project","path":repo_path},
                    {"type":"screenshot"}
                ],
                "expect_marker":"C-1001"
            },
            {
                "step_id": "s-2",
                "title":"Run tests",
                "actions":[ {"type":"run_command","cmd":"npm test"} ],
                "expect_marker":"C-1002"
            }
        ]
    }

@app.post("/missions")
def create_mission(m: MissionIn):
    mid = "m-" + str(uuid.uuid4())[:8]
    plan = simple_plan_for(m.prompt, m.repo_path)
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("INSERT INTO missions (id, user, prompt, repo_path, mac_id, status, plan_json) VALUES (?,?,?,?,?,?,?)",
              (mid, m.user, m.prompt, m.repo_path, m.mac_id, "pending", json.dumps(plan)))
    conn.commit()
    conn.close()
    return {"mission_id": mid, "plan": plan}

@app.get("/missions/{mission_id}")
def get_mission(mission_id: str):
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id, user, prompt, repo_path, mac_id, status, plan_json FROM missions WHERE id=?", (mission_id,))
    row = c.fetchone()
    conn.close()
    if not row:
        raise HTTPException(404, "mission not found")
    return {
        "id": row[0], "user": row[1], "prompt": row[2], "repo_path": row[3],
        "mac_id": row[4], "status": row[5], "plan": json.loads(row[6])
    }

@app.get("/missions/{mission_id}/next_step")
def next_step(mission_id: str, mac_id: str = "mac-01"):
    # Very simple: return first not completed step according to events in events table
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT plan_json FROM missions WHERE id=?", (mission_id,))
    row = c.fetchone()
    if not row:
        conn.close()
        raise HTTPException(404, "mission not found")
    plan = json.loads(row[0])["plan"]
    # check events to see which steps are done
    c.execute("SELECT step_id FROM events WHERE mission_id=?", (mission_id,))
    done = {r[0] for r in c.fetchall()}
    conn.close()
    for step in plan:
        if step["step_id"] not in done:
            return {"step": step}
    return {"step": None}

@app.post("/missions/{mission_id}/events")
def post_event(mission_id: str, event: EventIn):
    eid = "e-" + str(uuid.uuid4())[:8]
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    payload = json.dumps(event.dict())
    c.execute("INSERT INTO events (id, mission_id, step_id, payload) VALUES (?,?,?,?)",
              (eid, mission_id, event.step_id, payload))
    conn.commit()
    conn.close()
    return {"ok": True, "event_id": eid}

# Run with: uvicorn app.main:app --port 5757 --reload
How to run locally
python -m venv venv && source venv/bin/activate
pip install fastapi uvicorn python-dotenv
Save file as backend/app/main.py
uvicorn backend.app.main:app --port 5757 --reload
POST /missions with JSON to http://localhost:5757/missions using curl or Postman.
When you’re ready, replace simple_plan_for with a real Gemini call that returns JSON (validate shape).
macOS client minimal snippets & checklist
Requirements for mac client (dev)
Python 3.11+, pip
Enable Accessibility & Screen Recording permissions (System Settings → Privacy → Accessibility, Screen Recording)
Install dependencies: pip install -r mac-client/requirements.txt
Run as background service: python mac-client/main.py

Basic Python code for screenshot & HTTP POST
```python
import pyautogui
import requests
import base64
from io import BytesIO
from PIL import Image

def take_screenshot():
    screenshot = pyautogui.screenshot()
    buffer = BytesIO()
    screenshot.save(buffer, format='PNG')
    return base64.b64encode(buffer.getvalue()).decode('utf-8')

def post_event(mission_id, step_id, status, screenshot_data=None):
    json_data = {
        "mac_id": "mac-01",
        "step_id": step_id,
        "status": status
    }
    if screenshot_data:
        json_data["screenshots"] = [f"data:image/png;base64,{screenshot_data}"]
    
    response = requests.post(
        f"http://localhost:5757/missions/{mission_id}/events",
        json=json_data
    )
    return response.json()
```

mac-client/requirements.txt
```
pyautogui>=0.9.54
macuiauto>=1.0.0
watchdog>=3.0.0
pillow>=10.0.0
requests>=2.31.0
python-dotenv>=1.0.0
google-generativeai>=0.3.0  # For Gemini Vision API
```

Start with screenshot + POST and a manual step runner to confirm backend receives events.
Gemini usage notes (in .env)
GEMINI_API_KEY=your_key_here
ai_planner.py should:
Construct prompt: include mission prompt, repo_path, and strict output instruction: “Return JSON with field plan which is an array of steps; each step must have step_id, title, actions and optional expect_marker. Output only JSON.”
Validate the response with json.loads(...) and basic schema checks.
If invalid, retry or fallback to default sample plan.
Testing & demo script (short)
Start backend: uvicorn backend.app.main:app --port 5757 --reload
Open mac client and grant Accessibility & Screen Recording.
Run iOS client in Simulator or use curl to submit a mission:
curl -X POST http://localhost:5757/missions -H "Content-Type: application/json" -d '{"user":"ali","prompt":"create todo app","repo_path":"/Users/ali/Projects/todo","mac_id":"mac-01"}'
mac client polls /next_step, receives open_app action → opens Kiro, takes screenshot → POST event.
Manually edit a file to add //C 1001 → mac detects marker and posts event → backend returns next step.
Simulate failure for a step: run tests that fail → backend calls Gemini (or you manually craft a patch) → backend sends apply_patch step → mac applies and re-runs tests → pass → final success.
Record 2–3 minute video: show phone submit → mac opens Kiro → automated edits/tests → phone displays “Done”.
Simple rules and safety
Keep automation to the user’s own machine and repos only (local demo).
Request required permissions from user and show clear instructions.
Always create a git branch before applying AI patches.
Validate Gemini outputs strictly (expect JSON) to avoid code corruption.