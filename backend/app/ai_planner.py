"""AI planner using Gemini API to generate mission plans."""
import os
import json
import logging
from typing import Dict, Any, List
import google.generativeai as genai
from dotenv import load_dotenv

logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Configure Gemini API
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.0-flash-exp")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)


def get_static_plan(mission_id: str, prompt: str, repo_path: str) -> Dict[str, Any]:
    """Generate a static fallback plan.
    
    Args:
        mission_id: Mission identifier
        prompt: User's mission prompt
        repo_path: Repository path
        
    Returns:
        Dictionary containing mission plan
    """
    return {
        "mission_id": mission_id,
        "plan": [
            {
                "step_id": "s-1",
                "title": "Open Kiro and open project",
                "actions": [
                    {"type": "open_app", "app": "Kiro"},
                    {"type": "open_project", "path": repo_path},
                    {"type": "screenshot"}
                ],
                "expect_marker": "C-1001"
            },
            {
                "step_id": "s-2",
                "title": "Run tests",
                "actions": [
                    {"type": "run_command", "cmd": "npm test"}
                ],
                "expect_marker": "C-1002"
            }
        ]
    }


def validate_plan(plan: Dict[str, Any]) -> bool:
    """Validate plan structure.
    
    Args:
        plan: Plan dictionary to validate
        
    Returns:
        True if valid, False otherwise
    """
    try:
        # Check required fields
        if "mission_id" not in plan:
            logger.error("Plan missing mission_id")
            return False
        
        if "plan" not in plan or not isinstance(plan["plan"], list):
            logger.error("Plan missing or invalid plan array")
            return False
        
        # Validate each step
        for step in plan["plan"]:
            if not isinstance(step, dict):
                logger.error("Step is not a dictionary")
                return False
            
            if "step_id" not in step:
                logger.error("Step missing step_id")
                return False
            
            if "title" not in step:
                logger.error("Step missing title")
                return False
            
            if "actions" not in step or not isinstance(step["actions"], list):
                logger.error("Step missing or invalid actions array")
                return False
        
        return True
        
    except Exception as e:
        logger.error(f"Plan validation error: {e}")
        return False


def plan_from_prompt(mission_id: str, prompt: str, repo_path: str) -> Dict[str, Any]:
    """Generate a mission plan from a user prompt using Gemini API.
    
    Args:
        mission_id: Mission identifier
        prompt: User's mission description
        repo_path: Local repository path
        
    Returns:
        Dictionary containing mission plan with steps and actions
    """
    # Check if API key is configured
    if not GEMINI_API_KEY:
        logger.warning("GEMINI_API_KEY not configured, using static fallback plan")
        return get_static_plan(mission_id, prompt, repo_path)
    
    try:
        # Create Gemini model
        model = genai.GenerativeModel(GEMINI_MODEL)
        
        # Construct prompt for Gemini
        system_prompt = f"""You are an AI assistant that generates execution plans for software development tasks.

Given a user prompt and repository path, generate a JSON plan with the following structure:
{{
  "mission_id": "{mission_id}",
  "plan": [
    {{
      "step_id": "s-1",
      "title": "Step title",
      "actions": [
        {{"type": "open_app", "app": "Kiro"}},
        {{"type": "open_project", "path": "{repo_path}"}},
        {{"type": "screenshot"}},
        {{"type": "run_command", "cmd": "npm test"}},
        {{"type": "prompt_kiro_ai", "prompt": "Create a component"}}
      ],
      "expect_marker": "C-1001"
    }}
  ]
}}

Available action types:
- open_app: Open an application (e.g., Kiro)
- open_project: Open project in Kiro
- screenshot: Take a screenshot
- run_command: Run a shell command
- prompt_kiro_ai: Send prompt to Kiro AI
- wait_for_marker: Wait for a code marker (//C N)
- apply_patch: Apply code changes

User prompt: {prompt}
Repository path: {repo_path}

Generate a practical plan with 2-4 steps. Each step should have a unique step_id (s-1, s-2, etc.) and expect_marker (C-1001, C-1002, etc.).
Output ONLY valid JSON, no additional text."""

        # Generate plan
        logger.info(f"Generating plan for mission {mission_id} using Gemini API")
        response = model.generate_content(system_prompt)
        
        # Parse response
        response_text = response.text.strip()
        
        # Remove markdown code blocks if present
        if response_text.startswith("```json"):
            response_text = response_text[7:]
        if response_text.startswith("```"):
            response_text = response_text[3:]
        if response_text.endswith("```"):
            response_text = response_text[:-3]
        
        response_text = response_text.strip()
        
        # Parse JSON
        plan = json.loads(response_text)
        
        # Validate plan
        if not validate_plan(plan):
            logger.warning("Generated plan failed validation, using static fallback")
            return get_static_plan(mission_id, prompt, repo_path)
        
        logger.info(f"Successfully generated plan for mission {mission_id}")
        return plan
        
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse Gemini response as JSON: {e}")
        logger.warning("Using static fallback plan")
        return get_static_plan(mission_id, prompt, repo_path)
        
    except Exception as e:
        logger.error(f"Error generating plan with Gemini: {e}")
        logger.warning("Using static fallback plan")
        return get_static_plan(mission_id, prompt, repo_path)
