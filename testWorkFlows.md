# Test Workflows

## Overview

This document provides detailed test workflows for each development phase. Use these to verify functionality at each step.

---

## Test Workflow 1: Backend Skeleton (Step 1)

### Prerequisites
- Python 3.11+ installed
- Virtual environment created

### Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install fastapi uvicorn python-dotenv
```

### Test Steps

1. **Start Backend**
   ```bash
   uvicorn app.main:app --port 5757 --reload
   ```
   ✅ Expected: Server starts, shows "Uvicorn running on http://127.0.0.1:5757"

2. **Check Health Endpoint** (if added)
   ```bash
   curl http://localhost:5757/
   ```
   ✅ Expected: FastAPI docs or welcome message

3. **Create Mission**
   ```bash
   curl -X POST http://localhost:5757/missions \
     -H "Content-Type: application/json" \
     -d '{
       "user": "ali",
       "prompt": "Create a todo app",
       "repo_path": "/Users/ali/Projects/todo",
       "mac_id": "mac-01"
     }'
   ```
   ✅ Expected: Returns JSON with `mission_id` and `plan`

4. **Verify Database**
   ```bash
   sqlite3 db.sqlite "SELECT * FROM missions;"
   ```
   ✅ Expected: Mission record exists in database

5. **Get Mission**
   ```bash
   curl http://localhost:5757/missions/{mission_id}
   ```
   ✅ Expected: Returns mission JSON with all fields

### Success Criteria
- ✅ Backend starts without errors
- ✅ Mission created and stored in database
- ✅ Can retrieve mission by ID
- ✅ Database file `db.sqlite` created

---

## Test Workflow 2: Backend API Complete (Step 2)

### Prerequisites
- Step 1 completed
- Backend running

### Test Steps

1. **Create Mission**
   ```bash
   MISSION_RESPONSE=$(curl -X POST http://localhost:5757/missions \
     -H "Content-Type: application/json" \
     -d '{
       "user": "ali",
       "prompt": "Test mission",
       "repo_path": "/Users/ali/test",
       "mac_id": "mac-01"
     }')
   
   MISSION_ID=$(echo $MISSION_RESPONSE | jq -r '.mission_id')
   echo "Mission ID: $MISSION_ID"
   ```

2. **Get Next Step** (should return first step)
   ```bash
   curl "http://localhost:5757/missions/$MISSION_ID/next_step?mac_id=mac-01"
   ```
   ✅ Expected: Returns JSON with `step` object containing step_id, title, actions

3. **Post Event** (mark step as completed)
   ```bash
   curl -X POST "http://localhost:5757/missions/$MISSION_ID/events" \
     -H "Content-Type: application/json" \
     -d '{
       "mac_id": "mac-01",
       "step_id": "s-1",
       "status": "completed",
       "stdout": "Step completed successfully",
       "stderr": "",
       "found_markers": ["C-1001"]
     }'
   ```
   ✅ Expected: Returns `{"ok": true, "event_id": "e-..."}`

4. **Get Next Step Again** (should return next step or null)
   ```bash
   curl "http://localhost:5757/missions/$MISSION_ID/next_step?mac_id=mac-01"
   ```
   ✅ Expected: Returns next step or `{"step": null}` if all done

5. **Get All Steps**
   ```bash
   curl "http://localhost:5757/missions/$MISSION_ID/steps"
   ```
   ✅ Expected: Returns full plan with all steps

6. **Verify Events in Database**
   ```bash
   sqlite3 db.sqlite "SELECT * FROM events WHERE mission_id='$MISSION_ID';"
   ```
   ✅ Expected: Event record exists

### Success Criteria
- ✅ Can poll for next step
- ✅ Can post events
- ✅ Backend tracks step completion
- ✅ Next step updates after event posted
- ✅ Events stored in database

---

## Test Workflow 3: AI Planner (Step 3)

### Prerequisites
- Step 2 completed
- Gemini API key in `.env`

### Setup
```bash
# Add to backend/.env
echo "GEMINI_API_KEY=your_key_here" >> backend/.env
```

### Test Steps

1. **Create Mission with AI Planning**
   ```bash
   curl -X POST http://localhost:5757/missions \
     -H "Content-Type: application/json" \
     -d '{
       "user": "ali",
       "prompt": "Create a Next.js todo app with add/delete functionality",
       "repo_path": "/Users/ali/Projects/todo",
       "mac_id": "mac-01"
     }'
   ```
   ✅ Expected: Returns mission with AI-generated plan (or static fallback if API fails)

2. **Verify Plan Structure**
   ```bash
   curl "http://localhost:5757/missions/$MISSION_ID" | jq '.plan'
   ```
   ✅ Expected: Plan contains array of steps, each with step_id, title, actions, expect_marker

3. **Test Static Fallback** (if Gemini fails)
   - Temporarily use invalid API key
   - Create mission
   - ✅ Expected: Returns static plan (fallback)

4. **Test Plan Validation**
   - Backend should validate plan JSON structure
   - ✅ Expected: Invalid plans rejected or fallback used

### Success Criteria
- ✅ AI planner generates valid plan JSON
- ✅ Plan stored in database
- ✅ Fallback works if API fails
- ✅ Plan structure validated

---

## Test Workflow 4: Mac Client Skeleton (Step 4)

### Prerequisites
- Steps 1-3 completed
- Backend running
- Python 3.11+ on macOS

### Setup
```bash
cd mac-client
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Test Steps

1. **Start Mac Client**
   ```bash
   python main.py
   ```
   ✅ Expected: Client starts, begins polling backend

2. **Create Mission from Backend** (separate terminal)
   ```bash
   curl -X POST http://localhost:5757/missions \
     -H "Content-Type: application/json" \
     -d '{
       "user": "ali",
       "prompt": "Test mission",
       "repo_path": "/Users/ali/test",
       "mac_id": "mac-01"
     }'
   ```

3. **Observe Mac Client Logs**
   - ✅ Expected: Mac client polls backend every 3-5 seconds
   - ✅ Expected: Logs show "Polling for next step..."
   - ✅ Expected: Logs show step received or "No step available"

4. **Post Test Event from Mac Client**
   - Mac client should post event when step received
   - ✅ Expected: Event appears in backend database

5. **Check Backend Logs**
   - ✅ Expected: Backend receives GET requests for next_step
   - ✅ Expected: Backend receives POST requests for events

### Success Criteria
- ✅ Mac client connects to backend
- ✅ Polling works (every 3-5 seconds)
- ✅ Can post events
- ✅ No connection errors

---

## Test Workflow 5: Basic Automation Actions (Step 5)

### Prerequisites
- Step 4 completed
- Mac client running
- Kiro app installed (or use any app for testing)

### Test Steps

1. **Create Mission with Basic Actions**
   ```bash
   curl -X POST http://localhost:5757/missions \
     -H "Content-Type: application/json" \
     -d '{
       "user": "ali",
       "prompt": "Open Kiro and take screenshot",
       "repo_path": "/Users/ali/test",
       "mac_id": "mac-01"
     }'
   ```
   Plan should include:
   ```json
   {
     "step_id": "s-1",
     "title": "Open Kiro and screenshot",
     "actions": [
       {"type": "open_app", "app": "Kiro"},
       {"type": "screenshot"},
       {"type": "run_command", "cmd": "echo 'test'"}
     ]
   }
   ```

2. **Observe Mac Client Execution**
   - ✅ Expected: Mac client opens Kiro app
   - ✅ Expected: Takes screenshot
   - ✅ Expected: Runs command
   - ✅ Expected: Posts event with screenshot and stdout

3. **Verify Event in Backend**
   ```bash
   sqlite3 backend/db.sqlite "SELECT payload FROM events WHERE step_id='s-1';" | jq
   ```
   ✅ Expected: Event contains screenshot (base64) and stdout

4. **Test Each Action Individually**
   - Test `open_app` with different apps
   - Test `screenshot` quality
   - Test `run_command` with various commands
   - ✅ Expected: All actions execute successfully

### Success Criteria
- ✅ Can open apps
- ✅ Can take screenshots
- ✅ Can run shell commands
- ✅ Events include action results

---

## Test Workflow 6: Marker Watcher (Step 6)

### Prerequisites
- Step 5 completed
- Test repository with files

### Setup
```bash
mkdir -p /Users/ali/test_repo
cd /Users/ali/test_repo
echo "// Test file" > test.js
```

### Test Steps

1. **Create Mission Expecting Marker**
   ```bash
   curl -X POST http://localhost:5757/missions \
     -H "Content-Type: application/json" \
     -d '{
       "user": "ali",
       "prompt": "Wait for marker",
       "repo_path": "/Users/ali/test_repo",
       "mac_id": "mac-01"
     }'
   ```
   Plan should include:
   ```json
   {
     "step_id": "s-1",
     "title": "Wait for marker",
     "actions": [
       {"type": "wait_for_marker", "marker": "C-1001"}
     ],
     "expect_marker": "C-1001"
   }
   ```

2. **Mac Client Executes Step**
   - ✅ Expected: Step executor registers marker expectation
   - ✅ Expected: Marker Watcher starts watching repo_path

3. **Manually Add Marker**
   ```bash
   echo "//C 1001" >> /Users/ali/test_repo/test.js
   ```
   ✅ Expected: Marker Watcher detects change, scans file, finds marker

4. **Verify Marker Detection**
   - ✅ Expected: Marker Watcher notifies Mission Controller
   - ✅ Expected: Step marked as completed
   - ✅ Expected: Event posted with `found_markers: ["C-1001"]`

5. **Test Multiple Markers**
   - Add `//C 1002` to another file
   - ✅ Expected: Both markers detected if expected

6. **Test Marker Pattern Matching**
   - Try variations: `//C 1001`, `// C 1001`, `//C1001`
   - ✅ Expected: Regex matches all valid patterns

### Success Criteria
- ✅ Marker Watcher detects file changes
- ✅ Finds markers in files
- ✅ Notifies controller when expected marker found
- ✅ Step completes when marker detected

---

## Test Workflow 7: Kiro AI Integration (Step 7)

### Prerequisites
- Step 6 completed
- Kiro app installed and accessible
- Test project in Kiro

### Test Steps

1. **Create Mission with Kiro AI Prompt**
   ```bash
   curl -X POST http://localhost:5757/missions \
     -H "Content-Type: application/json" \
     -d '{
       "user": "ali",
       "prompt": "Ask Kiro AI to create a todo component",
       "repo_path": "/Users/ali/Projects/todo",
       "mac_id": "mac-01"
     }'
   ```
   Plan should include:
   ```json
   {
     "step_id": "s-1",
     "title": "Prompt Kiro AI",
     "actions": [
       {"type": "open_app", "app": "Kiro"},
       {"type": "open_project", "path": "/Users/ali/Projects/todo"},
       {"type": "prompt_kiro_ai", "prompt": "Create a todo component"}
     ]
   }
   ```

2. **Mac Client Executes**
   - ✅ Expected: Opens Kiro
   - ✅ Expected: Opens project (Cmd+O or Accessibility API)
   - ✅ Expected: Finds AI chat input field
   - ✅ Expected: Types prompt
   - ✅ Expected: Submits (Enter key)

3. **Verify AI Interaction**
   - Manually check Kiro: AI prompt should be sent
   - ✅ Expected: Kiro AI responds

4. **Test File List Extraction**
   - If AI response includes file list, extract it
   - ✅ Expected: File list extracted and stored

5. **Test Keyboard Shortcuts**
   - Test Cmd+O to open project
   - Test other Kiro shortcuts
   - ✅ Expected: Shortcuts work correctly

### Success Criteria
- ✅ Can find Kiro AI chat input
- ✅ Can type and submit prompts
- ✅ Can open projects in Kiro
- ✅ Can extract information from AI responses

---

## Test Workflow 8: Complete Edit/Test/Fix Loop (Step 8)

### Prerequisites
- Steps 1-7 completed
- Test project with failing test

### Setup
```bash
cd /Users/ali/Projects/todo
# Create a simple failing test
echo "test('should fail', () => { expect(1).toBe(2); });" > test.js
```

### Test Steps

1. **Create Mission to Fix Test**
   ```bash
   curl -X POST http://localhost:5757/missions \
     -H "Content-Type: application/json" \
     -d '{
       "user": "ali",
       "prompt": "Fix the failing test in test.js",
       "repo_path": "/Users/ali/Projects/todo",
       "mac_id": "mac-01"
     }'
   ```

2. **Backend Creates Plan**
   - Plan should include:
     - Open Kiro, open project
     - Run tests (will fail)
     - Analyze failure
     - Generate fix
     - Apply patch
     - Run tests again (should pass)
     - Add marker

3. **Mac Client Executes Full Loop**
   - ✅ Expected: Opens Kiro, opens project
   - ✅ Expected: Runs tests, detects failure
   - ✅ Expected: Backend calls AI for fix suggestion
   - ✅ Expected: Mac client applies patch
   - ✅ Expected: Runs tests again, passes
   - ✅ Expected: Adds marker `//C 1001`
   - ✅ Expected: Mission completes

4. **Verify Results**
   ```bash
   # Check test file was fixed
   cat /Users/ali/Projects/todo/test.js
   
   # Check marker was added
   grep "//C" /Users/ali/Projects/todo/test.js
   
   # Check mission status
   curl "http://localhost:5757/missions/$MISSION_ID" | jq '.status'
   ```
   ✅ Expected: Test fixed, marker added, mission status = "done"

5. **Test Screenshot Analysis**
   - Take screenshot of Kiro
   - Send to Gemini Vision API
   - Extract file list or status
   - ✅ Expected: AI correctly identifies files/elements

### Success Criteria
- ✅ Complete mission executes automatically
- ✅ Tests pass after fix
- ✅ Markers added correctly
- ✅ Mission status updates to "done"
- ✅ Screenshot analysis works

---

## End-to-End Test: Full Demo Workflow

### Complete Scenario
1. **iOS submits mission**: "Create a Next.js todo app"
2. **Backend creates plan**: 5-6 steps
3. **Mac client executes**:
   - Opens Kiro
   - Opens project
   - Prompts Kiro AI
   - Edits files
   - Runs tests
   - Fixes failures
   - Completes mission
4. **iOS shows progress**: Real-time updates, screenshots, completion

### Success Criteria
- ✅ Entire workflow completes without manual intervention
- ✅ All steps execute in correct order
- ✅ Mission completes successfully
- ✅ iOS app shows final "Done" status

---

## Troubleshooting

### Common Issues

1. **Backend not starting**
   - Check port 5757 not in use
   - Check Python version (3.11+)
   - Check dependencies installed

2. **Mac client can't connect**
   - Check backend running
   - Check `BACKEND_URL` in config
   - Check firewall settings

3. **Actions not executing**
   - Check Accessibility permissions
   - Check Screen Recording permissions
   - Check app names match exactly

4. **Markers not detected**
   - Check file path correct
   - Check marker format (`//C 1001`)
   - Check file watcher permissions

5. **Kiro AI not found**
   - Check Kiro app name
   - Check Accessibility API access
   - Check UI element selectors

---

## Performance Benchmarks

- **Backend response time**: < 100ms
- **Mac client polling**: Every 3-5 seconds
- **Marker detection**: < 1 second after file change
- **Screenshot capture**: < 500ms
- **AI planning**: 2-5 seconds (Gemini API)

