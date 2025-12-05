"""Screenshot capture actions."""
import pyautogui
import base64
from io import BytesIO
from PIL import Image
from utils.logger import setup_logger

logger = setup_logger("screenshot_actions")


def take_screenshot() -> str:
    """Take a screenshot and return as base64 encoded string.
    
    Returns:
        Base64 encoded PNG image string with data URI prefix
    """
    try:
        logger.info("Taking screenshot...")
        
        # Capture screenshot
        screenshot = pyautogui.screenshot()
        
        # Convert to base64
        buffer = BytesIO()
        screenshot.save(buffer, format='PNG')
        img_bytes = buffer.getvalue()
        img_base64 = base64.b64encode(img_bytes).decode('utf-8')
        
        # Add data URI prefix
        data_uri = f"data:image/png;base64,{img_base64}"
        
        logger.info(f"Screenshot captured ({len(img_base64)} bytes)")
        return data_uri
        
    except Exception as e:
        logger.error(f"Error taking screenshot: {e}")
        return ""


def take_screenshot_region(x: int, y: int, width: int, height: int) -> str:
    """Take a screenshot of a specific region.
    
    Args:
        x: X coordinate of top-left corner
        y: Y coordinate of top-left corner
        width: Width of region
        height: Height of region
        
    Returns:
        Base64 encoded PNG image string with data URI prefix
    """
    try:
        logger.info(f"Taking screenshot of region ({x}, {y}, {width}, {height})")
        
        # Capture screenshot of region
        screenshot = pyautogui.screenshot(region=(x, y, width, height))
        
        # Convert to base64
        buffer = BytesIO()
        screenshot.save(buffer, format='PNG')
        img_bytes = buffer.getvalue()
        img_base64 = base64.b64encode(img_bytes).decode('utf-8')
        
        # Add data URI prefix
        data_uri = f"data:image/png;base64,{img_base64}"
        
        logger.info(f"Region screenshot captured ({len(img_base64)} bytes)")
        return data_uri
        
    except Exception as e:
        logger.error(f"Error taking region screenshot: {e}")
        return ""
