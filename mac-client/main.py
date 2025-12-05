"""macOS Client - Entry point."""
import sys
from agents.mission_controller import MissionController
from config import MAC_ID, BACKEND_URL, POLL_INTERVAL
from utils.logger import setup_logger

logger = setup_logger("main")


def main():
    """Main entry point for macOS client."""
    logger.info("=== macOS Client Starting ===")
    logger.info(f"MAC_ID: {MAC_ID}")
    logger.info(f"Backend URL: {BACKEND_URL}")
    logger.info(f"Poll Interval: {POLL_INTERVAL}s")
    
    # Check if mission ID provided as argument
    if len(sys.argv) > 1:
        mission_id = sys.argv[1]
        logger.info(f"Mission ID provided: {mission_id}")
    else:
        logger.info("No mission ID provided. Waiting for mission...")
        logger.info("Usage: python main.py <mission_id>")
        logger.info("\nExample:")
        logger.info("  python main.py m-abc123")
        return
    
    # Create and start Mission Controller
    controller = MissionController(
        mac_id=MAC_ID,
        backend_url=BACKEND_URL,
        poll_interval=POLL_INTERVAL
    )
    
    # Set mission
    controller.set_mission(mission_id)
    
    # Start polling loop
    try:
        controller.run()
    except KeyboardInterrupt:
        logger.info("\nShutting down gracefully...")
        controller.stop()
    
    logger.info("=== macOS Client Stopped ===")


if __name__ == "__main__":
    main()
