"""API route handlers for the backend."""
import uuid
import json
import logging
from fastapi import APIRouter, HTTPException, status, Query
from app.models import MissionIn, MissionOut, MissionCreateResponse, EventIn
from app.db import create_mission, get_mission_by_id, create_event, get_completed_step_ids
from app.ai_planner import plan_from_prompt

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/missions", response_model=MissionCreateResponse, status_code=status.HTTP_201_CREATED)
async def create_new_mission(mission: MissionIn):
    """Create a new mission.
    
    Args:
        mission: Mission data from request body
        
    Returns:
        MissionCreateResponse with mission_id and plan
        
    Raises:
        HTTPException: 422 for validation errors, 500 for database errors
    """
    try:
        # Generate unique mission ID
        mission_id = f"m-{str(uuid.uuid4())[:8]}"
        
        # Generate plan using AI planner
        plan = plan_from_prompt(mission_id, mission.prompt, mission.repo_path)
        
        # Prepare mission data for database
        mission_data = {
            "id": mission_id,
            "user": mission.user,
            "prompt": mission.prompt,
            "repo_path": mission.repo_path,
            "mac_id": mission.mac_id,  # Will use default "mac-01" if not provided
            "status": "pending",
            "plan_json": json.dumps(plan)
        }
        
        # Store in database
        create_mission(mission_data)
        
        logger.info(f"Mission created: {mission_id} by user {mission.user}")
        
        return MissionCreateResponse(
            mission_id=mission_id,
            plan=plan
        )
        
    except Exception as e:
        logger.error(f"Failed to create mission: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create mission: {str(e)}"
        )


@router.get("/missions/{mission_id}", response_model=MissionOut)
async def get_mission(mission_id: str):
    """Retrieve a mission by ID.
    
    Args:
        mission_id: Mission identifier
        
    Returns:
        MissionOut with mission details
        
    Raises:
        HTTPException: 404 if mission not found, 500 for database errors
    """
    try:
        mission = get_mission_by_id(mission_id)
        
        if mission is None:
            logger.warning(f"Mission not found: {mission_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="mission not found"
            )
        
        logger.info(f"Mission retrieved: {mission_id}")
        
        return MissionOut(**mission)
        
    except HTTPException:
        # Re-raise HTTP exceptions (like 404)
        raise
    except Exception as e:
        logger.error(f"Failed to retrieve mission {mission_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve mission: {str(e)}"
        )


@router.get("/missions/{mission_id}/next_step")
async def get_next_step(mission_id: str, mac_id: str = Query(default="mac-01")):
    """Get the next step for a macOS client to execute.
    
    Args:
        mission_id: Mission identifier
        mac_id: macOS client identifier (query parameter)
        
    Returns:
        JSON with next step or null if no steps remaining
        
    Raises:
        HTTPException: 404 if mission not found, 500 for database errors
    """
    try:
        # Get mission
        mission = get_mission_by_id(mission_id)
        
        if mission is None:
            logger.warning(f"Mission not found: {mission_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="mission not found"
            )
        
        # Get plan
        plan = mission.get("plan", {})
        steps = plan.get("plan", [])
        
        # Get completed step IDs
        completed_steps = get_completed_step_ids(mission_id)
        
        # Find first uncompleted step
        for step in steps:
            step_id = step.get("step_id")
            if step_id not in completed_steps:
                logger.info(f"Next step for mission {mission_id}: {step_id}")
                return {"step": step}
        
        # No steps remaining
        logger.info(f"No steps remaining for mission {mission_id}")
        return {"step": None}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get next step for mission {mission_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get next step: {str(e)}"
        )


@router.post("/missions/{mission_id}/events")
async def post_event(mission_id: str, event: EventIn):
    """Post an event for a mission step.
    
    Args:
        mission_id: Mission identifier
        event: Event data from request body
        
    Returns:
        JSON with ok status and event_id
        
    Raises:
        HTTPException: 404 if mission not found, 500 for database errors
    """
    try:
        # Verify mission exists
        mission = get_mission_by_id(mission_id)
        
        if mission is None:
            logger.warning(f"Mission not found: {mission_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="mission not found"
            )
        
        # Generate event ID
        event_id = f"e-{str(uuid.uuid4())[:8]}"
        
        # Prepare event data
        event_data = {
            "id": event_id,
            "mission_id": mission_id,
            "step_id": event.step_id,
            "payload": json.dumps(event.dict())
        }
        
        # Store event
        create_event(event_data)
        
        logger.info(f"Event posted: {event_id} for mission {mission_id}, step {event.step_id}, status {event.status}")
        
        return {"ok": True, "event_id": event_id}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to post event for mission {mission_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to post event: {str(e)}"
        )


@router.get("/missions/{mission_id}/steps")
async def get_steps(mission_id: str):
    """Get all steps for a mission.
    
    Args:
        mission_id: Mission identifier
        
    Returns:
        JSON with full plan containing all steps
        
    Raises:
        HTTPException: 404 if mission not found, 500 for database errors
    """
    try:
        # Get mission
        mission = get_mission_by_id(mission_id)
        
        if mission is None:
            logger.warning(f"Mission not found: {mission_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="mission not found"
            )
        
        # Return plan
        plan = mission.get("plan", {})
        logger.info(f"Steps retrieved for mission {mission_id}")
        
        return plan
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get steps for mission {mission_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get steps: {str(e)}"
        )
