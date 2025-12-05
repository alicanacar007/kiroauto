# Step-by-Step Development Phases

## Overview

This document breaks down development into **8 manageable steps** that can be completed incrementally. Each step builds on the previous one and includes a clear goal, deliverables, and test criteria.

---

## Step 1: Backend Skeleton & Database Setup
**Goal**: Get FastAPI backend running with SQLite database

**Deliverables**:
- ✅ FastAPI app running on port 5757
- ✅ SQLite database with missions and events tables
- ✅ Basic endpoints: POST `/missions`, GET `/missions/{id}`
- ✅ Can create and retrieve missions via curl/Postman

**Files to Create**:
```
backend/app/main.py
backend/app/db.py
backend/app/models.py
backend/app/routes.py
backend/requirements.txt
backend/.env
```

**Test**:
```bash
# Start backend
cd backend
uvicorn app.main:app --port 5757 --reload

# Test POST mission
curl -X POST http://localhost:5757/missions \
  -H "Content-Type: application/json" \
  -d '{"user":"ali","prompt":"test","repo_path":"/Users/ali/test","mac_id":"mac-01"}'

# Test GET mission
curl http://localhost:5757/missions/{mission_id}
```

**Success Criteria**: Backend responds, mission stored in database, can retrieve mission

---

## Step 2: Backend API - Next Step & Events Endpoints
**Goal**: Complete backend API for step polling and event reporting

**Deliverables**:
- ✅ GET `/missions/{id}/next_step?mac_id=mac-01` endpoint
- ✅ POST `/missions/{id}/events` endpoint
- ✅ GET `/missions/{id}/steps` endpoint (view full plan)
- ✅ Backend tracks step completion via events

**Files to Modify**:
```
backend/app/routes.py  # Add new endpoints
backend/app/db.py      # Add helper functions
```

**Test**:
```bash
# Get next step (should return null initially)
curl "http://localhost:5757/missions/{mission_id}/next_step?mac_id=mac-01"

# Post event
curl -X POST http://localhost:5757/missions/{mission_id}/events \
  -H "Content-Type: application/json" \
  -d '{"mac_id":"mac-01","step_id":"s-1","status":"completed","stdout":"done"}'

# Get steps
curl http://localhost:5757/missions/{mission_id}/steps
```

**Success Criteria**: Can poll for steps, post events, backend tracks completion

---

## Step 3: AI Planner Integration (Static Plan First)
**Goal**: Connect Gemini API and generate mission plans (start with static fallback)

**Deliverables**:
- ✅ `ai_planner.py` with `plan_from_prompt()` function
- ✅ Static plan generator (fallback)
- ✅ Gemini API integration (with error handling)
- ✅ Plan validation (JSON schema check)
- ✅ Backend calls planner on mission creation

**Files to Create**:
```
backend/app/ai_planner.py
```

**Files to Modify**:
```
backend/app/routes.py  # Call planner in POST /missions
backend/.env           # Add GEMINI_API_KEY
```

**Test**:
```bash
# Create mission with AI planning
curl -X POST http://localhost:5757/missions \
  -H "Content-Type: application/json" \
  -d '{"user":"ali","prompt":"create todo app","repo_path":"/Users/ali/todo","mac_id":"mac-01"}'

# Check plan in response and database
curl http://localhost:5757/missions/{mission_id}
```

**Success Criteria**: Mission creation returns plan JSON, plan stored in database, can retrieve plan

---

## Step 4: macOS Client Skeleton & HTTP Communication
**Goal**: Python macOS client that can communicate with backend

**Deliverables**:
- ✅ `mac-client/main.py` entry point
- ✅ `mac-client/utils/http_client.py` for backend communication
- ✅ `mac-client/config.py` for configuration
- ✅ Can poll backend for next step
- ✅ Can post events to backend

**Files to Create**:
```
mac-client/main.py
mac-client/config.py
mac-client/utils/http_client.py
mac-client/utils/logger.py
mac-client/requirements.txt
```

**Test**:
```bash
# Start backend (from Step 1-3)
# Start mac client
cd mac-client
python main.py

# Should see polling logs, can post test event
```

**Success Criteria**: Mac client connects to backend, polls successfully, can post events

---

## Step 5: Basic Automation Actions (Open App, Screenshot, Run Command)
**Goal**: Mac client can perform basic automation actions

**Deliverables**:
- ✅ `actions/app_actions.py` - open_app, check_if_open
- ✅ `actions/screenshot_actions.py` - take_screenshot, encode_base64
- ✅ `actions/file_actions.py` - run_command (subprocess)
- ✅ `agents/step_executor.py` - executes actions from step
- ✅ Can execute: open_app, screenshot, run_command actions

**Files to Create**:
```
mac-client/actions/app_actions.py
mac-client/actions/screenshot_actions.py
mac-client/actions/file_actions.py
mac-client/agents/step_executor.py
```

**Test**:
```bash
# Create mission with step containing these actions
# Mac client should:
# 1. Open Kiro app
# 2. Take screenshot
# 3. Run "npm test" in repo
# 4. Post event with screenshot and stdout
```

**Success Criteria**: Mac client opens Kiro, takes screenshot, runs command, posts results

---

## Step 6: Marker Watcher & File Monitoring
**Goal**: Parallel agent that watches files for `//C N` markers

**Deliverables**:
- ✅ `agents/marker_watcher.py` - file watcher using watchdog
- ✅ Marker detection regex `//C \d+`
- ✅ Runs in background thread (parallel)
- ✅ Notifies Mission Controller when marker found
- ✅ Can detect manually added markers

**Files to Create**:
```
mac-client/agents/marker_watcher.py
```

**Files to Modify**:
```
mac-client/main.py  # Start Marker Watcher thread
mac-client/agents/mission_controller.py  # Handle marker notifications
```

**Test**:
```bash
# 1. Create mission with step expecting marker C-1001
# 2. Mac client executes step, waits for marker
# 3. Manually add //C 1001 to a file in repo
# 4. Marker Watcher detects it → posts event → step completes
```

**Success Criteria**: Marker Watcher detects markers, notifies controller, step completes

---

## Step 7: Kiro AI Integration & Input Actions
**Goal**: Interact with Kiro AI chat and handle keyboard/mouse input

**Deliverables**:
- ✅ `agents/kiro_automator.py` - Kiro-specific automation
- ✅ `actions/input_actions.py` - click, type, keyboard shortcuts
- ✅ Can find Kiro AI chat input (Accessibility API)
- ✅ Can type prompt and submit
- ✅ Can open project in Kiro (Cmd+O)
- ✅ Can extract file list from AI response

**Files to Create**:
```
mac-client/agents/kiro_automator.py
mac-client/actions/input_actions.py
```

**Test**:
```bash
# Create mission with step:
# - open_app: Kiro
# - open_project: /path/to/repo
# - prompt_kiro_ai: "Create a todo app"
# Mac client should:
# 1. Open Kiro
# 2. Open project (Cmd+O)
# 3. Find AI chat input
# 4. Type prompt
# 5. Submit
# 6. Wait for response
```

**Success Criteria**: Can interact with Kiro AI, extract file list, proceed to next step

---

## Step 8: Screenshot Analysis & File Editing Loop
**Goal**: Complete edit/test/fix loop with AI vision and file operations

**Deliverables**:
- ✅ `agents/screenshot_analyzer.py` - Gemini Vision API integration
- ✅ `actions/file_actions.py` - edit_file, apply_patch, git operations
- ✅ Can analyze screenshots to extract file lists
- ✅ Can edit files based on AI suggestions
- ✅ Can run tests, detect failures, apply fixes
- ✅ Complete test → fix → test loop

**Files to Create/Modify**:
```
mac-client/agents/screenshot_analyzer.py
mac-client/actions/file_actions.py  # Add edit_file, apply_patch
backend/app/ai_planner.py            # Add patch generation for failures
```

**Test**:
```bash
# Create mission: "Fix failing test in todo app"
# Backend creates plan:
# 1. Open Kiro, open project
# 2. Run tests (fails)
# 3. Analyze failure → AI suggests fix
# 4. Apply patch
# 5. Run tests again (passes)
# 6. Add marker //C 1001
# Mac client executes all steps automatically
```

**Success Criteria**: Complete mission executes automatically, tests pass, mission completes

---

## Development Order Summary

1. **Backend Skeleton** → Get API running
2. **Backend API Complete** → Step polling & events
3. **AI Planner** → Mission planning
4. **Mac Client Skeleton** → HTTP communication
5. **Basic Actions** → Open app, screenshot, commands
6. **Marker Watcher** → File monitoring
7. **Kiro AI Integration** → Kiro-specific automation
8. **Complete Loop** → Edit/test/fix automation

## Testing Strategy

After each step:
1. **Unit Tests**: Test individual functions
2. **Integration Tests**: Test component interactions
3. **End-to-End Test**: Test full workflow
4. **Manual Test**: Use curl/Postman to verify

## Next Steps After Step 8

- **Phase 4**: Watchdog for stuck steps
- **Phase 5**: iOS client UI polish
- **Demo**: Record video, prepare presentation

---

## Quick Start Checklist

- [ ] Step 1: Backend skeleton
- [ ] Step 2: Backend API complete
- [ ] Step 3: AI planner
- [ ] Step 4: Mac client skeleton
- [ ] Step 5: Basic actions
- [ ] Step 6: Marker watcher
- [ ] Step 7: Kiro AI integration
- [ ] Step 8: Complete loop

