"""Mission Controller - Main orchestrator that polls backend."""
import time
from typing import Optional
from utils.http_client import HTTPClient
from utils.logger import setup_logger
from agents.step_executor import StepExecutor

logger = setup_logger("mission_controller")


class MissionController:
    """Main orchestrator that polls backend and manages mission flow."""
    
    def __init__(self, mac_id: str, backend_url: str, poll_interval: int = 3):
        """Initialize Mission Controller.
        
        Args:
            mac_id: macOS client identifier
            backend_url: Backend server URL
            poll_interval: Polling interval in seconds
        """
        self.mac_id = mac_id
        self.poll_interval = poll_interval
        self.http_client = HTTPClient(backend_url)
        self.step_executor = StepExecutor()
        self.current_mission_id: Optional[str] = None
        self.current_repo_path: Optional[str] = None
        self.running = False
    
    def set_mission(self, mission_id: str):
        """Set the current mission to execute.
        
        Args:
            mission_id: Mission identifier
        """
        self.current_mission_id = mission_id
        logger.info(f"Mission set: {mission_id}")
        
        # Get mission details to extract repo_path
        mission = self.http_client.get_mission(mission_id)
        if mission:
            self.current_repo_path = mission.get("repo_path")
            logger.info(f"Repository path: {self.current_repo_path}")
    
    def get_next_step(self) -> Optional[dict]:
        """Get the next step from backend.
        
        Returns:
            Step data or None if no steps remaining
        """
        if not self.current_mission_id:
            logger.warning("No mission set")
            return None
        
        step = self.http_client.get_next_step(self.current_mission_id, self.mac_id)
        
        if step:
            logger.info(f"Next step: {step.get('step_id')} - {step.get('title')}")
        else:
            logger.info("No steps remaining")
        
        return step
    
    def report_event(self, step_id: str, status: str, **kwargs):
        """Report an event to the backend.
        
        Args:
            step_id: Step identifier
            status: Event status (running, completed, failed)
            **kwargs: Additional event data (stdout, stderr, screenshots, etc.)
        """
        event_data = {
            "mac_id": self.mac_id,
            "step_id": step_id,
            "status": status,
            **kwargs
        }
        
        success = self.http_client.post_event(self.current_mission_id, event_data)
        
        if success:
            logger.info(f"Event reported: {step_id} - {status}")
        else:
            logger.error(f"Failed to report event: {step_id}")
    
    def run(self):
        """Main polling loop with adaptive intervals."""
        self.running = True
        logger.info(f"Mission Controller started (polling every {self.poll_interval}s)")
        
        consecutive_empty_polls = 0
        max_empty_polls = 3
        
        while self.running:
            try:
                # Get next step
                step = self.get_next_step()
                
                if step:
                    # Reset empty poll counter when we get a step
                    consecutive_empty_polls = 0
                    
                    step_id = step.get("step_id")
                    logger.info(f"Executing step: {step_id}")
                    
                    # Report step started
                    self.report_event(step_id, "running")
                    
                    # Execute step actions
                    results = self.step_executor.execute(step, self.current_repo_path)
                    
                    # Report step completed or failed
                    if results["success"]:
                        self.report_event(
                            step_id,
                            "completed",
                            stdout=results.get("stdout", ""),
                            stderr=results.get("stderr", ""),
                            screenshots=results.get("screenshots", [])
                        )
                    else:
                        self.report_event(
                            step_id,
                            "failed",
                            stdout=results.get("stdout", ""),
                            stderr=results.get("stderr", ""),
                            screenshots=results.get("screenshots", [])
                        )
                    
                    # Shorter wait after executing a step
                    wait_time = max(1, self.poll_interval // 2)
                else:
                    # No steps remaining - use adaptive waiting
                    consecutive_empty_polls += 1
                    
                    if consecutive_empty_polls >= max_empty_polls:
                        if self.current_mission_id:
                            logger.info("Mission complete!")
                            self.current_mission_id = None
                        # Longer wait when no steps available
                        wait_time = self.poll_interval * 2
                    else:
                        # Progressive backoff when waiting for steps
                        wait_time = self.poll_interval + (consecutive_empty_polls * 2)
                
                # Wait before next poll
                time.sleep(wait_time)
                
            except KeyboardInterrupt:
                logger.info("Shutting down...")
                self.running = False
                break
            except Exception as e:
                logger.error(f"Error in main loop: {e}")
                # Exponential backoff on errors
                error_wait = min(self.poll_interval * 2, 10)
                time.sleep(error_wait)
    
    def stop(self):
        """Stop the mission controller."""
        self.running = False
        logger.info("Mission Controller stopped")
