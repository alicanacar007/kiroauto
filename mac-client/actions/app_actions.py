"""Application control actions."""
import subprocess
import time
from utils.logger import setup_logger

logger = setup_logger("app_actions")


def open_app(app_name: str) -> bool:
    """Open an application on macOS.
    
    Args:
        app_name: Name of the application to open
        
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info(f"Opening app: {app_name}")
        
        # Use macOS 'open' command
        result = subprocess.run(
            ["open", "-a", app_name],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0:
            logger.info(f"Successfully opened {app_name}")
            time.sleep(2)  # Wait for app to launch
            return True
        else:
            logger.error(f"Failed to open {app_name}: {result.stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        logger.error(f"Timeout opening {app_name}")
        return False
    except Exception as e:
        logger.error(f"Error opening {app_name}: {e}")
        return False


def check_if_open(app_name: str) -> bool:
    """Check if an application is currently running.
    
    Args:
        app_name: Name of the application
        
    Returns:
        True if running, False otherwise
    """
    try:
        result = subprocess.run(
            ["pgrep", "-x", app_name],
            capture_output=True,
            text=True
        )
        
        is_running = result.returncode == 0
        logger.info(f"{app_name} is {'running' if is_running else 'not running'}")
        return is_running
        
    except Exception as e:
        logger.error(f"Error checking if {app_name} is open: {e}")
        return False


def focus_app(app_name: str) -> bool:
    """Bring an application to the foreground.
    
    Args:
        app_name: Name of the application
        
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info(f"Focusing app: {app_name}")
        
        # Use AppleScript to activate the app
        script = f'tell application "{app_name}" to activate'
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode == 0:
            logger.info(f"Successfully focused {app_name}")
            time.sleep(1)  # Wait for focus
            return True
        else:
            logger.error(f"Failed to focus {app_name}: {result.stderr}")
            return False
            
    except Exception as e:
        logger.error(f"Error focusing {app_name}: {e}")
        return False
