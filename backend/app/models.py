"""Pydantic models for request validation and response serialization."""
from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, Dict, Any


class MissionIn(BaseModel):
    """Request model for creating a new mission."""
    
    user: str = Field(..., description="Username who submitted the mission")
    prompt: str = Field(..., description="Mission description/prompt")
    repo_path: str = Field(..., description="Local repository path")
    mac_id: Optional[str] = Field(default="mac-01", description="Assigned macOS client ID")
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "user": "alice",
                "prompt": "Create a Next.js todo app",
                "repo_path": "/Users/alice/Projects/todo",
                "mac_id": "mac-01"
            }
        }
    )


class MissionOut(BaseModel):
    """Response model for mission details."""
    
    id: str = Field(..., description="Mission identifier")
    user: str = Field(..., description="Username who submitted the mission")
    prompt: str = Field(..., description="Mission description/prompt")
    repo_path: str = Field(..., description="Local repository path")
    mac_id: str = Field(..., description="Assigned macOS client ID")
    status: str = Field(..., description="Mission status (pending, running, done, failed)")
    plan: Dict[str, Any] = Field(..., description="Mission execution plan")
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "id": "m-a1b2c3d4",
                "user": "alice",
                "prompt": "Create a Next.js todo app",
                "repo_path": "/Users/alice/Projects/todo",
                "mac_id": "mac-01",
                "status": "pending",
                "plan": {
                    "mission_id": "m-a1b2c3d4",
                    "plan": []
                }
            }
        }
    )


class MissionCreateResponse(BaseModel):
    """Response model for mission creation."""
    
    mission_id: str = Field(..., description="The created mission identifier")
    plan: Dict[str, Any] = Field(..., description="Mission execution plan")
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "mission_id": "m-a1b2c3d4",
                "plan": {
                    "mission_id": "m-a1b2c3d4",
                    "plan": []
                }
            }
        }
    )


class EventIn(BaseModel):
    """Request model for posting mission events (for future use in Step 2)."""
    
    mac_id: str = Field(..., description="macOS client ID")
    step_id: str = Field(..., description="Step identifier")
    status: str = Field(..., description="Event status (running, completed, failed, stalled)")
    stdout: Optional[str] = Field(default="", description="Standard output from step execution")
    stderr: Optional[str] = Field(default="", description="Standard error from step execution")
    screenshots: Optional[list] = Field(default=None, description="Base64 encoded screenshots")
    found_markers: Optional[list] = Field(default=None, description="Markers found in code")
