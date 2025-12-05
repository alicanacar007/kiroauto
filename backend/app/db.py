"""Database initialization and helper functions for SQLite."""
import sqlite3
import logging
import os
from typing import Optional, Dict, Any
import json

logger = logging.getLogger(__name__)

# Get the backend directory (parent of app directory)
BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_FILE = os.path.join(BACKEND_DIR, "db.sqlite")

# Log the database path for debugging
print(f"Database file path: {DB_FILE}")


def get_connection() -> sqlite3.Connection:
    """Get a database connection with performance optimizations."""
    conn = sqlite3.connect(DB_FILE, timeout=10.0)
    conn.row_factory = sqlite3.Row  # Enable column access by name
    
    # Enable WAL mode for better concurrency and performance
    conn.execute("PRAGMA journal_mode=WAL")
    # Optimize for performance
    conn.execute("PRAGMA synchronous=NORMAL")  # Faster than FULL, safer than OFF
    conn.execute("PRAGMA cache_size=-64000")  # 64MB cache (negative = KB)
    conn.execute("PRAGMA temp_store=MEMORY")  # Store temp tables in memory
    
    return conn


def init_db() -> None:
    """Initialize the database with required tables.
    
    This function is idempotent - it can be called multiple times safely.
    Tables are created with IF NOT EXISTS to prevent errors on subsequent calls.
    """
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        # Create missions table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS missions (
                id TEXT PRIMARY KEY,
                user TEXT NOT NULL,
                prompt TEXT NOT NULL,
                repo_path TEXT NOT NULL,
                mac_id TEXT NOT NULL,
                status TEXT NOT NULL,
                plan_json TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Create events table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS events (
                id TEXT PRIMARY KEY,
                mission_id TEXT NOT NULL,
                step_id TEXT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                payload TEXT NOT NULL,
                FOREIGN KEY (mission_id) REFERENCES missions(id)
            )
        """)
        
        # Create indexes for better query performance
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_events_mission_id ON events(mission_id)
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_events_step_id ON events(step_id)
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_events_mission_step ON events(mission_id, step_id)
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_missions_status ON missions(status)
        """)
        
        conn.commit()
        conn.close()
        
        logger.info("Database initialized successfully")
        
    except sqlite3.Error as e:
        logger.error(f"Database initialization failed: {e}")
        raise


def create_mission(mission_data: Dict[str, Any]) -> str:
    """Create a new mission in the database.
    
    Args:
        mission_data: Dictionary containing mission fields
        
    Returns:
        The mission ID of the created mission
        
    Raises:
        sqlite3.Error: If database operation fails
    """
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO missions (id, user, prompt, repo_path, mac_id, status, plan_json)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            mission_data["id"],
            mission_data["user"],
            mission_data["prompt"],
            mission_data["repo_path"],
            mission_data["mac_id"],
            mission_data["status"],
            mission_data.get("plan_json")
        ))
        
        conn.commit()
        mission_id = mission_data["id"]
        conn.close()
        
        logger.info(f"Mission created: {mission_id}")
        return mission_id
        
    except sqlite3.Error as e:
        logger.error(f"Failed to create mission: {e}")
        raise


def get_mission_by_id(mission_id: str) -> Optional[Dict[str, Any]]:
    """Retrieve a mission by its ID.
    
    Args:
        mission_id: The mission identifier
        
    Returns:
        Dictionary containing mission data, or None if not found
    """
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, user, prompt, repo_path, mac_id, status, plan_json
            FROM missions
            WHERE id = ?
        """, (mission_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if row:
            return {
                "id": row["id"],
                "user": row["user"],
                "prompt": row["prompt"],
                "repo_path": row["repo_path"],
                "mac_id": row["mac_id"],
                "status": row["status"],
                "plan": json.loads(row["plan_json"]) if row["plan_json"] else {}
            }
        
        return None
        
    except sqlite3.Error as e:
        logger.error(f"Failed to retrieve mission {mission_id}: {e}")
        raise


def create_event(event_data: Dict[str, Any]) -> str:
    """Create a new event in the database.
    
    Args:
        event_data: Dictionary containing event fields
        
    Returns:
        The event ID of the created event
        
    Raises:
        sqlite3.Error: If database operation fails
    """
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO events (id, mission_id, step_id, payload)
            VALUES (?, ?, ?, ?)
        """, (
            event_data["id"],
            event_data["mission_id"],
            event_data.get("step_id"),
            event_data["payload"]
        ))
        
        conn.commit()
        event_id = event_data["id"]
        conn.close()
        
        logger.info(f"Event created: {event_id} for mission {event_data['mission_id']}")
        return event_id
        
    except sqlite3.Error as e:
        logger.error(f"Failed to create event: {e}")
        raise


def get_completed_step_ids(mission_id: str) -> set:
    """Get all completed step IDs for a mission.
    
    Args:
        mission_id: The mission identifier
        
    Returns:
        Set of completed step IDs
    """
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT DISTINCT step_id
            FROM events
            WHERE mission_id = ? AND step_id IS NOT NULL
        """, (mission_id,))
        
        rows = cursor.fetchall()
        conn.close()
        
        return {row["step_id"] for row in rows}
        
    except sqlite3.Error as e:
        logger.error(f"Failed to get completed steps for mission {mission_id}: {e}")
        raise
