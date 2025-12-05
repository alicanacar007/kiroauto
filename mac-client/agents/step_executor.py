"""Step Executor - Executes step actions sequentially."""
import os
from typing import Dict, Any, List
from actions.app_actions import open_app, focus_app, check_if_open
from actions.screenshot_actions import take_screenshot
from actions.file_actions import run_command
from actions.input_actions import open_project_in_kiro, prompt_kiro_ai, wait_for_kiro_completion
from utils.logger import setup_logger

logger = setup_logger("step_executor")


class StepExecutor:
    """Executes individual step actions sequentially."""
    
    def __init__(self):
        """Initialize Step Executor."""
        self.current_step = None
    
    def execute(self, step: Dict[str, Any], repo_path: str = None) -> Dict[str, Any]:
        """Execute a step's actions.
        
        Args:
            step: Step data containing actions to execute
            repo_path: Repository path for commands
            
        Returns:
            Dictionary with execution results
        """
        self.current_step = step
        step_id = step.get("step_id")
        title = step.get("title")
        actions = step.get("actions", [])
        
        logger.info(f"Executing step {step_id}: {title}")
        logger.info(f"Actions to execute: {len(actions)}")
        
        results = {
            "step_id": step_id,
            "success": True,
            "stdout": "",
            "stderr": "",
            "screenshots": [],
            "errors": []
        }
        
        # Execute each action
        for i, action in enumerate(actions):
            action_type = action.get("type")
            logger.info(f"Action {i+1}/{len(actions)}: {action_type}")
            
            try:
                action_result = self.execute_action(action, repo_path)
                
                # Collect results
                if action_result.get("stdout"):
                    results["stdout"] += action_result["stdout"] + "\n"
                if action_result.get("stderr"):
                    results["stderr"] += action_result["stderr"] + "\n"
                if action_result.get("screenshot"):
                    results["screenshots"].append(action_result["screenshot"])
                
                # Check if action failed
                if not action_result.get("success", True):
                    results["success"] = False
                    error_msg = f"Action {action_type} failed: {action_result.get('error', 'Unknown error')}"
                    results["errors"].append(error_msg)
                    logger.error(error_msg)
                    
            except Exception as e:
                results["success"] = False
                error_msg = f"Exception in action {action_type}: {str(e)}"
                results["errors"].append(error_msg)
                logger.error(error_msg)
        
        logger.info(f"Step {step_id} execution {'succeeded' if results['success'] else 'failed'}")
        return results
    
    def execute_action(self, action: Dict[str, Any], repo_path: str = None) -> Dict[str, Any]:
        """Execute a single action.
        
        Args:
            action: Action data
            repo_path: Repository path for commands
            
        Returns:
            Dictionary with action results
        """
        action_type = action.get("type")
        result = {"success": True}
        
        if action_type == "open_app":
            app_name = action.get("app")
            success = open_app(app_name)
            result["success"] = success
            result["stdout"] = f"Opened {app_name}" if success else f"Failed to open {app_name}"
            
        elif action_type == "screenshot":
            screenshot = take_screenshot()
            result["screenshot"] = screenshot
            result["success"] = bool(screenshot)
            result["stdout"] = "Screenshot captured" if screenshot else "Failed to capture screenshot"
            
        elif action_type == "run_command":
            cmd = action.get("cmd")
            cwd = action.get("cwd", repo_path)
            return_code, stdout, stderr = run_command(cmd, cwd=cwd)
            result["success"] = return_code == 0
            result["stdout"] = stdout
            result["stderr"] = stderr
            
        elif action_type == "open_project":
            path = action.get("path")
            success = open_project_in_kiro(path)
            result["success"] = success
            result["stdout"] = f"Opened project: {path}" if success else f"Failed to open project: {path}"
            
        elif action_type == "prompt_kiro_ai":
            prompt = action.get("prompt")
            success = prompt_kiro_ai(prompt)
            result["success"] = success
            result["stdout"] = f"Sent prompt to Kiro AI: {prompt}" if success else f"Failed to send prompt to Kiro AI"
            
            # After sending prompt, wait for Kiro.app to complete work
            if success:
                expected_files = action.get("expected_files")  # Optional: files to wait for
                wait_timeout = action.get("wait_timeout", 30)  # Default 30 seconds
                logger.info("Waiting for Kiro.app to complete work after prompt...")
                wait_success = wait_for_kiro_completion(
                    repo_path=repo_path,
                    timeout=wait_timeout,
                    expected_files=expected_files
                )
                if wait_success:
                    result["stdout"] += "\nKiro.app work completion detected"
                else:
                    result["stdout"] += "\nKiro.app work completion wait finished (timeout or no files detected)"
            
        elif action_type == "wait_for_marker":
            # Will implement in Step 6
            marker = action.get("marker")
            logger.info(f"Wait for marker: {marker} (not yet implemented)")
            result["stdout"] = f"Waiting for marker {marker} (simulated)"
            
        elif action_type == "wait_for_file":
            from actions.file_actions import wait_for_file
            file_path = action.get("file_path")
            timeout = action.get("timeout", 60)
            if file_path:
                # Make path absolute if repo_path is provided
                if repo_path and not os.path.isabs(file_path):
                    file_path = os.path.join(repo_path, file_path)
                found = wait_for_file(file_path, timeout=timeout)
                result["success"] = found
                result["stdout"] = f"File {'found' if found else 'not found'}: {file_path}"
            else:
                result["success"] = False
                result["error"] = "wait_for_file action requires 'file_path' parameter"
            
        elif action_type == "wait_for_kiro_completion":
            expected_files = action.get("expected_files")
            timeout = action.get("timeout", 30)
            wait_success = wait_for_kiro_completion(
                repo_path=repo_path,
                timeout=timeout,
                expected_files=expected_files
            )
            result["success"] = wait_success
            result["stdout"] = "Kiro.app completion wait finished"
            
        else:
            logger.warning(f"Unknown action type: {action_type}")
            result["success"] = False
            result["error"] = f"Unknown action type: {action_type}"
        
        return result
