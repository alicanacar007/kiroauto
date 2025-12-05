# AutoIDE Controller Backend

FastAPI backend server for the Auto-IDE Controller system. Manages missions, stores data in SQLite, and coordinates between iOS clients and macOS automation clients.

## Setup

### Prerequisites
- Python 3.11 or higher
- pip (Python package manager)

### Installation

1. Create a virtual environment:
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Configure environment variables:
```bash
cp .env.example .env
# Edit .env and add your GEMINI_API_KEY
```

## Running the Server

Start the development server:
```bash
uvicorn app.main:app --port 5757 --reload
```

The server will start on `http://localhost:5757`

## API Endpoints

### POST /missions
Create a new mission.

**Request:**
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

**Response:**
```json
{
  "mission_id": "m-a1b2c3d4",
  "plan": {
    "mission_id": "m-a1b2c3d4",
    "plan": []
  }
}
```

### GET /missions/{mission_id}
Retrieve mission details by ID.

**Request:**
```bash
curl http://localhost:5757/missions/m-a1b2c3d4
```

**Response:**
```json
{
  "id": "m-a1b2c3d4",
  "user": "ali",
  "prompt": "Create a todo app",
  "repo_path": "/Users/ali/Projects/todo",
  "mac_id": "mac-01",
  "status": "pending",
  "plan": {
    "mission_id": "m-a1b2c3d4",
    "plan": []
  }
}
```

### GET /missions/{mission_id}/next_step
Get the next step for a macOS client to execute.

**Request:**
```bash
curl "http://localhost:5757/missions/m-a1b2c3d4/next_step?mac_id=mac-01"
```

**Response (with steps remaining):**
```json
{
  "step": {
    "step_id": "s-1",
    "title": "Open Kiro and project",
    "actions": [
      {"type": "open_app", "app": "Kiro"},
      {"type": "screenshot"}
    ]
  }
}
```

**Response (no steps remaining):**
```json
{
  "step": null
}
```

### POST /missions/{mission_id}/events
Post an event for a mission step.

**Request:**
```bash
curl -X POST "http://localhost:5757/missions/m-a1b2c3d4/events" \
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

**Response:**
```json
{
  "ok": true,
  "event_id": "e-xyz123"
}
```

### GET /missions/{mission_id}/steps
Get all steps for a mission (view full plan).

**Request:**
```bash
curl "http://localhost:5757/missions/m-a1b2c3d4/steps"
```

**Response:**
```json
{
  "mission_id": "m-a1b2c3d4",
  "plan": [
    {
      "step_id": "s-1",
      "title": "Open Kiro and project",
      "actions": []
    },
    {
      "step_id": "s-2",
      "title": "Run tests",
      "actions": []
    }
  ]
}
```

### GET /
Health check endpoint.

**Request:**
```bash
curl http://localhost:5757/
```

**Response:**
```json
{
  "message": "AutoIDE Controller API",
  "status": "running",
  "version": "1.0.0"
}
```

## Environment Variables

- `GEMINI_API_KEY`: Your Gemini API key (required for AI planning in Step 3)
- `GEMINI_MODEL`: Gemini model to use (default: gemini-2.5-flash)
- `GEMINI_LIVE_MODEL`: Gemini live model (default: gemini-2.0-flash)
- `GEMINI_FLUSH_INTERVAL_MS`: Flush interval in milliseconds (default: 750)

## Database

The backend uses SQLite for data storage. The database file `db.sqlite` is created automatically on first run.

### Tables

**missions**
- `id`: Mission identifier (format: m-{uuid})
- `user`: Username who submitted the mission
- `prompt`: Mission description
- `repo_path`: Local repository path
- `mac_id`: Assigned macOS client ID
- `status`: Mission status (pending, running, done, failed)
- `plan_json`: JSON string of mission plan
- `created_at`: Timestamp of creation

**events**
- `id`: Event identifier (format: e-{uuid})
- `mission_id`: Foreign key to missions table
- `step_id`: Step identifier
- `timestamp`: Event timestamp
- `payload`: JSON string of event data

## Development

### Running Tests
```bash
pytest
```

### API Documentation
FastAPI provides automatic interactive API documentation:
- Swagger UI: http://localhost:5757/docs
- ReDoc: http://localhost:5757/redoc

## Project Structure

```
backend/
├── app/
│   ├── __init__.py       # Package marker
│   ├── main.py           # FastAPI app and startup
│   ├── models.py         # Pydantic models
│   ├── db.py             # Database operations
│   └── routes.py         # API endpoints
├── requirements.txt      # Python dependencies
├── .env                  # Environment variables (not in git)
├── .env.example          # Example environment file
└── db.sqlite            # SQLite database (auto-created)
```

## AI Planning

The backend uses Gemini AI to generate mission plans automatically. When you create a mission, the AI analyzes your prompt and generates a structured plan with steps and actions.

### Example AI-Generated Plan

For prompt: "Build a React calculator app"

The AI generates:
- Step 1: Initialize React App and Create Calculator Component
- Step 2: Implement Calculator UI and Input Logic  
- Step 3: Add Calculation Logic and Error Handling

Each step includes specific actions like opening Kiro, prompting the AI, and running commands.

### Fallback Plan

If the Gemini API is unavailable or returns invalid JSON, the backend automatically uses a static fallback plan to ensure the system continues working.

## Next Steps

- **Step 4**: Build macOS client for automation
- **Step 5**: Implement basic automation actions
- **Step 6**: Add marker watcher for file monitoring
- **Step 7**: Integrate Kiro AI interactions
- **Step 8**: Complete edit/test/fix loop
