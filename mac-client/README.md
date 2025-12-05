# macOS Client

Python-based macOS client that executes missions by polling the backend and performing automation actions.

## Setup

### Prerequisites
- Python 3.9 or higher
- Backend server running on port 5757

### Installation

1. Install dependencies:
```bash
cd mac-client
pip3 install -r requirements.txt
```

2. Configure environment (optional):
```bash
cp .env.example .env
# Edit .env if needed
```

## Usage

### Running the Client

Start the client with a mission ID:
```bash
python3 main.py <mission_id>
```

Example:
```bash
python3 main.py m-abc123
```

The client will:
1. Connect to the backend
2. Poll for the next step every 3 seconds
3. Execute step actions (simulated in Step 4)
4. Report progress back to backend
5. Continue until all steps are complete

### Testing

1. Start the backend server:
```bash
cd backend
python3 -m uvicorn app.main:app --port 5757 --reload
```

2. Create a mission:
```bash
curl -X POST http://localhost:5757/missions \
  -H "Content-Type: application/json" \
  -d '{
    "user": "ali",
    "prompt": "Build a React calculator app",
    "repo_path": "/Users/ali/calculator"
  }'
```

3. Copy the mission_id from the response

4. Start the macOS client:
```bash
python3 main.py m-abc123
```

You should see:
- Client connecting to backend
- Polling for next step
- Executing steps (simulated)
- Reporting completion
- Mission complete when all steps done

## Configuration

Environment variables (in `.env`):
- `MAC_ID`: Client identifier (default: "mac-01")
- `BACKEND_URL`: Backend server URL (default: "http://localhost:5757")
- `POLL_INTERVAL`: Polling interval in seconds (default: 3)

## Architecture

```
mac-client/
├── main.py                      # Entry point
├── config.py                    # Configuration
├── agents/
│   └── mission_controller.py   # Main orchestrator
├── utils/
│   ├── http_client.py          # Backend API client
│   └── logger.py               # Logging setup
└── requirements.txt            # Dependencies
```

## Next Steps

- **Step 5**: Add action execution (open apps, screenshots, commands)
- **Step 6**: Add marker watcher for file monitoring
- **Step 7**: Add Kiro AI integration
- **Step 8**: Complete edit/test/fix loop
