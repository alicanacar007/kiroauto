"""HTTP client for backend communication."""
import requests
from typing import Optional, Dict, Any
from utils.logger import setup_logger

logger = setup_logger("http_client")


class HTTPClient:
    """HTTP client for communicating with the backend."""
    
    def __init__(self, backend_url: str):
        """Initialize HTTP client.
        
        Args:
            backend_url: Base URL of the backend server
        """
        self.backend_url = backend_url.rstrip('/')
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json'
        })
    
    def get_next_step(self, mission_id: str, mac_id: str) -> Optional[Dict[str, Any]]:
        """Get the next step for a mission.
        
        Args:
            mission_id: Mission identifier
            mac_id: macOS client identifier
            
        Returns:
            Dictionary with step data or None if no steps remaining
        """
        try:
            url = f"{self.backend_url}/missions/{mission_id}/next_step"
            params = {"mac_id": mac_id}
            
            response = self.session.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            return data.get("step")
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to get next step: {e}")
            return None
    
    def post_event(self, mission_id: str, event_data: Dict[str, Any]) -> bool:
        """Post an event for a mission step.
        
        Args:
            mission_id: Mission identifier
            event_data: Event data to post
            
        Returns:
            True if successful, False otherwise
        """
        try:
            url = f"{self.backend_url}/missions/{mission_id}/events"
            
            response = self.session.post(url, json=event_data, timeout=10)
            response.raise_for_status()
            
            result = response.json()
            logger.info(f"Event posted: {result.get('event_id')}")
            return True
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to post event: {e}")
            return False
    
    def get_mission(self, mission_id: str) -> Optional[Dict[str, Any]]:
        """Get mission details.
        
        Args:
            mission_id: Mission identifier
            
        Returns:
            Dictionary with mission data or None if not found
        """
        try:
            url = f"{self.backend_url}/missions/{mission_id}"
            
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            
            return response.json()
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to get mission: {e}")
            return None
