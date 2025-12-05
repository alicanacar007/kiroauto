# Parallel Agents Architecture

## Overview

The macOS client uses a **parallel agents architecture** where multiple specialized agents run concurrently to handle different aspects of mission execution. This design allows for efficient monitoring, execution, and coordination.

## Agent Components

### 1. Mission Controller (Main Orchestrator)
**Purpose**: Central coordinator that polls backend and manages mission flow

**Responsibilities**:
- Polls backend every 3-5 seconds for next step
- Tracks current mission state
- Coordinates with other agents
- Handles mission lifecycle (start, pause, resume, complete)

**Thread**: Main thread (blocking loop)

**Key Methods**:
```python
class MissionController:
    def get_next_step(self) -> Optional[dict]
    def report_event(self, mission_id, step_id, status, data)
    def run(self)  # Main loop
```

**Communication**:
- → Backend: GET `/missions/{id}/next_step`
- → Step Executor: Passes step to execute
- → Marker Watcher: Notifies when markers found
- ← Marker Watcher: Receives marker detection events

---

### 2. Step Executor (Action Runner)
**Purpose**: Executes individual step actions sequentially

**Responsibilities**:
- Receives step from Mission Controller
- Executes actions in order (open_app, click, type, run_command, etc.)
- Handles action failures and retries
- Reports step completion/failure to backend

**Thread**: Called from Mission Controller (same thread, but can be async)

**Key Methods**:
```python
class StepExecutor:
    def execute(self, step: dict, mission_id: str)
    def execute_action(self, action: dict, repo_path: str)
    def report_step_result(self, mission_id, step_id, status, data)
```

**Action Types Handled**:
- `open_app` → Uses app_actions.py
- `open_project` → Uses input_actions.py (keyboard shortcut)
- `click` → Uses input_actions.py
- `type` → Uses input_actions.py
- `screenshot` → Uses screenshot_actions.py
- `run_command` → Uses file_actions.py (subprocess)
- `apply_patch` → Uses file_actions.py
- `prompt_kiro_ai` → Uses kiro_automator.py
- `wait_for_marker` → Waits for Marker Watcher signal

**Communication**:
- ← Mission Controller: Receives step to execute
- → Backend: POST `/missions/{id}/events`
- → Marker Watcher: Registers marker expectation
- ← Marker Watcher: Receives marker found signal

---

### 3. Marker Watcher (File Monitor)
**Purpose**: Monitors file system for `//C N` markers in parallel

**Responsibilities**:
- Watches repo_path for file changes using watchdog
- Scans changed files for marker pattern `//C \d+`
- Notifies Mission Controller when expected marker found
- Runs continuously in background (parallel to main loop)

**Thread**: Separate background thread (daemon)

**Key Methods**:
```python
class MarkerWatcher:
    def start(self, repo_path: str)
    def watch_for_marker(self, mission_id: str, step_id: str, marker: str)
    def on_file_changed(self, file_path: str)  # Callback from watchdog
    def scan_file_for_markers(self, file_path: str) -> List[str]
```

**Marker Detection Logic**:
```python
import re
MARKER_PATTERN = r'//C\s*(\d+)'

def scan_file_for_markers(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
        markers = re.findall(MARKER_PATTERN, content)
        return [f"C-{m}" for m in markers]
```

**Communication**:
- ← Mission Controller: Registers marker expectation
- → Mission Controller: Notifies when marker found
- → Backend: POST event with found markers

---

### 4. Kiro Automator (Kiro-Specific Handler)
**Purpose**: Handles Kiro app-specific automation, especially AI chat interaction

**Responsibilities**:
- Finds Kiro AI chat input field using Accessibility API
- Types mission prompt into Kiro AI
- Submits prompt (Enter key)
- Waits for AI response
- Extracts file list or status from response
- Handles Kiro-specific keyboard shortcuts (Cmd+O, etc.)

**Thread**: Called from Step Executor (synchronous)

**Key Methods**:
```python
class KiroAutomator:
    def is_kiro_open(self) -> bool
    def open_kiro(self)
    def open_project(self, repo_path: str)
    def find_ai_chat_input(self) -> Optional[AXElement]
    def prompt_ai(self, prompt: str) -> dict
    def extract_file_list_from_response(self, response_text: str) -> List[str]
```

**Accessibility API Usage**:
```python
from macuiauto import MacUI

def find_ai_chat_input():
    app = MacUI.launchApp("Kiro")
    # Find AI chat input by accessibility label or role
    chat_input = app.findFirstR(AXTextField, {"role": "text field", "label": "AI chat"})
    return chat_input
```

**Communication**:
- ← Step Executor: Receives `prompt_kiro_ai` action
- → Step Executor: Returns file list or status

---

### 5. Screenshot Analyzer (AI Vision)
**Purpose**: Analyzes screenshots using AI vision to extract information

**Responsibilities**:
- Takes screenshots when requested
- Sends screenshots to Gemini Vision API
- Extracts file lists, UI elements, or status from screenshots
- Returns structured data (file paths, button locations, etc.)

**Thread**: Called from Step Executor (async/await or sync)

**Key Methods**:
```python
class ScreenshotAnalyzer:
    def take_screenshot(self) -> bytes
    def analyze_with_ai(self, screenshot: bytes, prompt: str) -> dict
    def extract_file_list(self, screenshot: bytes) -> List[str]
    def detect_ui_elements(self, screenshot: bytes) -> List[dict]
```

**Gemini Vision API Usage**:
```python
import google.generativeai as genai

def analyze_with_ai(screenshot_bytes, prompt):
    model = genai.GenerativeModel('gemini-pro-vision')
    response = model.generate_content([
        prompt,
        {"mime_type": "image/png", "data": screenshot_bytes}
    ])
    return parse_response(response.text)
```

**Communication**:
- ← Step Executor: Receives `analyze_screenshot` action
- → Step Executor: Returns extracted data

---

## Agent Communication Flow

### Normal Execution Flow
```
Mission Controller (polls backend)
    ↓ (gets step)
Step Executor (executes actions)
    ├─→ App Actions (open Kiro)
    ├─→ Kiro Automator (prompt AI)
    ├─→ Screenshot Analyzer (analyze screenshot)
    └─→ File Actions (edit files, run tests)
    ↓ (reports completion)
Backend (stores event)
```

### Marker Detection Flow
```
Marker Watcher (background thread)
    ↓ (file changed)
    ↓ (scans for markers)
    ↓ (finds //C 1001)
Mission Controller (receives notification)
    ↓ (marks step complete)
    ↓ (gets next step)
Step Executor (executes next step)
```

### Parallel Execution Example
```
Time 0s: Mission Controller polls → gets step s-1
Time 0s: Step Executor starts executing s-1
Time 0s: Marker Watcher starts watching for C-1001 (parallel)
Time 2s: Step Executor completes action → waits for marker
Time 5s: Marker Watcher detects C-1001 → notifies Mission Controller
Time 5s: Mission Controller marks s-1 complete → gets step s-2
Time 5s: Step Executor starts executing s-2
```

## Thread Safety

### Shared State
- **Current Mission ID**: Protected by lock (threading.Lock)
- **Marker Expectations**: Dictionary with lock (mission_id → step_id → marker)
- **File Watcher**: Thread-safe watchdog library

### Synchronization Points
```python
import threading

class MissionController:
    def __init__(self):
        self.lock = threading.Lock()
        self.marker_expectations = {}  # {mission_id: {step_id: marker}}
    
    def register_marker_expectation(self, mission_id, step_id, marker):
        with self.lock:
            if mission_id not in self.marker_expectations:
                self.marker_expectations[mission_id] = {}
            self.marker_expectations[mission_id][step_id] = marker
    
    def check_marker_found(self, mission_id, marker):
        with self.lock:
            # Check if this marker is expected for any step
            for step_id, expected_marker in self.marker_expectations.get(mission_id, {}).items():
                if marker == expected_marker:
                    return step_id
            return None
```

## Error Handling

### Agent Failures
- **Mission Controller failure**: Logs error, continues polling
- **Step Executor failure**: Reports failure to backend, waits for next step
- **Marker Watcher failure**: Restarts watcher thread, logs error
- **Kiro Automator failure**: Reports failure, backend can retry or replan
- **Screenshot Analyzer failure**: Falls back to manual detection or reports error

### Retry Logic
```python
class StepExecutor:
    def execute_action(self, action, max_retries=3):
        for attempt in range(max_retries):
            try:
                return self._execute_action(action)
            except Exception as e:
                if attempt == max_retries - 1:
                    raise
                time.sleep(2 ** attempt)  # Exponential backoff
```

## Performance Considerations

- **Polling Interval**: 3-5 seconds (configurable)
- **Marker Watcher**: Real-time file system events (efficient)
- **Screenshot Analysis**: Async/await to avoid blocking
- **Parallel Agents**: Minimal CPU usage when idle

## Future Enhancements

- **WebSocket Support**: Replace polling with WebSocket for real-time updates
- **Multiple Mission Support**: Handle multiple missions concurrently
- **Agent Health Monitoring**: Health checks and auto-restart
- **Distributed Agents**: Run agents on multiple machines

