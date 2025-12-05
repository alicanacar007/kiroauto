"""File and command execution actions."""
import subprocess
import os
import time
from typing import Tuple, Optional
from utils.logger import setup_logger

logger = setup_logger("file_actions")


def run_command(cmd: str, cwd: str = None, timeout: int = 60) -> Tuple[int, str, str]:
    """Run a shell command.
    
    Args:
        cmd: Command to run
        cwd: Working directory (optional)
        timeout: Timeout in seconds
        
    Returns:
        Tuple of (return_code, stdout, stderr)
    """
    try:
        logger.info(f"Running command: {cmd}")
        if cwd:
            logger.info(f"Working directory: {cwd}")
        
        # Run command
        result = subprocess.run(
            cmd,
            shell=True,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        
        logger.info(f"Command completed with return code: {result.returncode}")
        
        if result.stdout:
            logger.info(f"stdout: {result.stdout[:200]}...")  # Log first 200 chars
        if result.stderr:
            logger.warning(f"stderr: {result.stderr[:200]}...")
        
        return result.returncode, result.stdout, result.stderr
        
    except subprocess.TimeoutExpired:
        logger.error(f"Command timed out after {timeout}s")
        return -1, "", f"Command timed out after {timeout}s"
    except Exception as e:
        logger.error(f"Error running command: {e}")
        return -1, "", str(e)


def read_file(file_path: str) -> str:
    """Read contents of a file.
    
    Args:
        file_path: Path to file
        
    Returns:
        File contents as string
    """
    try:
        logger.info(f"Reading file: {file_path}")
        
        with open(file_path, 'r') as f:
            content = f.read()
        
        logger.info(f"Read {len(content)} bytes from {file_path}")
        return content
        
    except Exception as e:
        logger.error(f"Error reading file {file_path}: {e}")
        return ""


def write_file(file_path: str, content: str) -> bool:
    """Write content to a file.
    
    Args:
        file_path: Path to file
        content: Content to write
        
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info(f"Writing to file: {file_path}")
        
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        logger.info(f"Wrote {len(content)} bytes to {file_path}")
        return True
        
    except Exception as e:
        logger.error(f"Error writing file {file_path}: {e}")
        return False


def file_exists(file_path: str) -> bool:
    """Check if a file exists.
    
    Args:
        file_path: Path to file
        
    Returns:
        True if file exists, False otherwise
    """
    exists = os.path.exists(file_path)
    logger.info(f"File {file_path} {'exists' if exists else 'does not exist'}")
    return exists


def wait_for_file(file_path: str, timeout: int = 60, check_interval: float = 1.0) -> bool:
    """Wait for a file to be created, polling until it exists or timeout.
    
    This is useful when waiting for Kiro.app to create files after receiving a prompt.
    
    Args:
        file_path: Path to file to wait for
        timeout: Maximum time to wait in seconds (default: 60)
        check_interval: Time between checks in seconds (default: 1.0)
        
    Returns:
        True if file exists, False if timeout reached
    """
    logger.info(f"Waiting for file: {file_path} (timeout: {timeout}s)")
    
    start_time = time.time()
    while time.time() - start_time < timeout:
        if os.path.exists(file_path):
            elapsed = time.time() - start_time
            logger.info(f"File found after {elapsed:.1f}s: {file_path}")
            return True
        time.sleep(check_interval)
    
    logger.warning(f"Timeout waiting for file: {file_path} (waited {timeout}s)")
    return False


def wait_for_any_file(file_paths: list, timeout: int = 60, check_interval: float = 1.0) -> Tuple[bool, Optional[str]]:
    """Wait for any of the specified files to be created.
    
    Args:
        file_paths: List of file paths to check
        timeout: Maximum time to wait in seconds (default: 60)
        check_interval: Time between checks in seconds (default: 1.0)
        
    Returns:
        Tuple of (found: bool, file_path: Optional[str])
    """
    logger.info(f"Waiting for any of {len(file_paths)} files (timeout: {timeout}s)")
    
    start_time = time.time()
    while time.time() - start_time < timeout:
        for file_path in file_paths:
            if os.path.exists(file_path):
                elapsed = time.time() - start_time
                logger.info(f"File found after {elapsed:.1f}s: {file_path}")
                return True, file_path
        time.sleep(check_interval)
    
    logger.warning(f"Timeout waiting for files (waited {timeout}s)")
    return False, None
