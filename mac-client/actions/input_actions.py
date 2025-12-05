"""Input and interaction actions for Kiro app."""
import subprocess
import time
import json
import os
from typing import Optional
from utils.logger import setup_logger

logger = setup_logger("input_actions")

# State tracking to prevent duplicate actions
_last_prompt = None
_last_prompt_time = 0
_chat_open_state = False


def open_project_in_kiro(path: str) -> bool:
    """Open a project in Kiro app.
    
    Args:
        path: Path to the project directory
        
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info(f"Opening project in Kiro: {path}")
        
        # Ensure Kiro is running and focused first
        focus_script = 'tell application "Kiro" to activate'
        subprocess.run(
            ["osascript", "-e", focus_script],
            capture_output=True,
            timeout=5
        )
        time.sleep(0.2)  # Reduced from 0.5s
        
        # Use AppleScript to open project in Kiro
        # Use POSIX file to handle paths properly
        # Escape backslashes in path for AppleScript
        escaped_path = path.replace('\\', '\\\\')
        script = f'''
        tell application "Kiro"
            activate
            delay 0.3
            open POSIX file "{escaped_path}"
        end tell
        '''
        
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0:
            logger.info(f"Successfully opened project: {path}")
            time.sleep(0.5)  # Reduced from 0.8s - Wait for project to load
            return True
        else:
            error_msg = result.stderr or result.stdout
            logger.warning(f"Direct open failed: {error_msg}")
            # Try alternative method using Cmd+O
            return open_project_via_shortcut(path)
            
    except subprocess.TimeoutExpired:
        logger.error(f"Timeout opening project: {path}")
        return False
    except Exception as e:
        logger.error(f"Error opening project: {e}")
        return False


def open_project_via_shortcut(path: str) -> bool:
    """Alternative method: Use Cmd+O keyboard shortcut to open project.
    
    Args:
        path: Path to the project directory
        
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info(f"Trying Cmd+O method for: {path}")
        
        # First, ensure Kiro is focused
        focus_script = 'tell application "Kiro" to activate'
        subprocess.run(
            ["osascript", "-e", focus_script],
            capture_output=True,
            timeout=5
        )
        time.sleep(0.5)
        
        # Press Cmd+O
        shortcut_script = '''
        tell application "System Events"
            tell process "Kiro"
                keystroke "o" using command down
            end tell
        end tell
        '''
        subprocess.run(
            ["osascript", "-e", shortcut_script],
            capture_output=True,
            timeout=5
        )
        time.sleep(0.5)  # Reduced from 1s
        
        # Type the path and press Enter
        # Note: This assumes the file dialog is open
        path_script = f'''
        tell application "System Events"
            tell process "Kiro"
                keystroke "{path}"
                delay 0.3
                key code 36
            end tell
        end tell
        '''
        result = subprocess.run(
            ["osascript", "-e", path_script],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode == 0:
            time.sleep(0.5)  # Reduced from 1s
            return True
        return False
        
    except Exception as e:
        logger.error(f"Error with Cmd+O method: {e}")
        return False


def prompt_kiro_ai(prompt: str) -> bool:
    """Send a prompt to Kiro AI chat.
    
    This function:
    1. Focuses Kiro app
    2. Opens the AI chat panel using Cmd+L (only if not already open)
    3. Finds and clicks the chat input field to ensure focus
    4. Types the prompt
    5. Submits it (presses Enter)
    6. Waits for completion before returning
    
    Args:
        prompt: The prompt text to send to Kiro AI
        
    Returns:
        True if successful, False otherwise
    """
    global _last_prompt, _last_prompt_time, _chat_open_state
    
    try:
        # Check for duplicate prompts (same prompt within 2 seconds)
        current_time = time.time()
        if prompt == _last_prompt and (current_time - _last_prompt_time) < 2.0:
            logger.warning(f"Duplicate prompt detected, skipping: {prompt[:50]}...")
            return True  # Return success to avoid blocking
        
        logger.info(f"Sending prompt to Kiro AI: {prompt[:100]}...")
        _last_prompt = prompt
        _last_prompt_time = current_time
        
        # First, ensure Kiro is focused and active
        focus_script = 'tell application "Kiro" to activate'
        focus_result = subprocess.run(
            ["osascript", "-e", focus_script],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if focus_result.returncode != 0:
            logger.warning(f"Failed to focus Kiro: {focus_result.stderr}")
            # Try Option+Tab as fallback
            if not _is_kiro_frontmost():
                logger.info("Attempting Option+Tab to switch to Kiro")
                switch_to_kiro_with_option_tab()
        
        # Ensure Kiro is frontmost before opening chat
        if not _is_kiro_frontmost():
            logger.info("Kiro not frontmost, using Option+Tab to switch")
            switch_to_kiro_with_option_tab()
            time.sleep(0.8)  # Wait for app switch to complete
        else:
            time.sleep(0.5)  # Wait for Kiro to come to front
        
        # Check if chat is already open before opening it
        chat_already_open = _is_chat_open()
        if chat_already_open:
            logger.info("Chat panel already open, skipping Cmd+L")
            _chat_open_state = True
            time.sleep(0.3)  # Small delay to ensure UI is ready
        else:
            # Open chat with Cmd+L only if not already open
            logger.info("Opening chat panel with Cmd+L")
            open_chat_script = '''
            tell application "System Events"
                tell process "Kiro"
                    set frontmost to true
                    delay 0.3
                    -- Open chat with Cmd+L
                    keystroke "l" using command down
                    delay 1.0
                end tell
            end tell
            '''
            
            open_result = subprocess.run(
                ["osascript", "-e", open_chat_script],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if open_result.returncode != 0:
                logger.warning(f"Failed to open chat: {open_result.stderr}")
            
            time.sleep(0.8)  # Wait for chat panel to fully open
            _chat_open_state = True
        
        # Now find and click the chat input field
        # Try multiple strategies to find the input field
        find_input_script = '''
        tell application "System Events"
            tell process "Kiro"
                set frontmost to true
                delay 0.2
                try
                    -- Strategy 1: Look for text fields with placeholder text or specific descriptions
                    set textFields to every text field
                    set foundField to false
                    repeat with textField in textFields
                        try
                            set fieldValue to value of textField as string
                            set fieldDesc to description of textField as string
                            -- Look for input fields (often empty or have placeholder-like descriptions)
                            if fieldValue is "" or fieldDesc contains "input" or fieldDesc contains "question" or fieldDesc contains "task" then
                                click textField
                                delay 0.3
                                set foundField to true
                                exit repeat
                            end if
                        end try
                    end repeat
                    
                    -- Strategy 2: If no specific field found, click the last text field (usually the input)
                    if not foundField and (count of textFields) > 0 then
                        click (item -1 of textFields)
                        delay 0.3
                        set foundField to true
                    end if
                    
                    -- Strategy 3: If still not found, try using Tab to navigate to input field
                    if not foundField then
                        key code 48 -- Tab key
                        delay 0.2
                    end if
                on error
                    -- Fallback: Just try Tab navigation
                    key code 48
                    delay 0.2
                end try
            end tell
        end tell
        '''
        
        click_result = subprocess.run(
            ["osascript", "-e", find_input_script],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        # If input field detection might have failed, ensure Kiro is focused
        if click_result.returncode != 0:
            logger.warning("Input field detection may have failed, ensuring Kiro focus")
            if not _is_kiro_frontmost():
                switch_to_kiro_with_option_tab()
                time.sleep(0.3)
        
        time.sleep(0.1)  # Reduced from 0.3s - Small delay after clicking
        
        # Escape special characters for AppleScript
        # AppleScript string escaping: backslash, quotes, and newlines
        escaped_prompt = (
            prompt
            .replace('\\', '\\\\')  # Escape backslashes first
            .replace('"', '\\"')     # Escape quotes
            .replace('\n', '\\n')    # Escape newlines
            .replace('\r', '\\r')    # Escape carriage returns
        )
        
        # Now type the prompt
        type_script = f'''
        tell application "System Events"
            tell process "Kiro"
                set frontmost to true
                delay 0.2
                -- Clear any existing text first (Cmd+A then delete)
                keystroke "a" using command down
                delay 0.1
                key code 51 -- Delete key
                delay 0.1
                -- Type the prompt
                keystroke "{escaped_prompt}"
                delay 0.2
                -- Send with Enter
                key code 36
            end tell
        end tell
        '''
        
        result = subprocess.run(
            ["osascript", "-e", type_script],
            capture_output=True,
            text=True,
            timeout=15
        )
        
        if result.returncode == 0:
            logger.info("Successfully sent prompt to Kiro AI")
            # Wait longer for Kiro to process the prompt before allowing next action
            logger.info("Waiting for Kiro to process prompt...")
            time.sleep(3.0)  # Increased wait time to ensure prompt is processed
            return True
        else:
            error_msg = result.stderr or result.stdout
            logger.warning(f"Typing failed: {error_msg}")
            
            # Try alternative: Use mouse clicking with better element finding
            return prompt_kiro_ai_alternative(prompt)
            
    except subprocess.TimeoutExpired:
        logger.error("Timeout sending prompt to Kiro AI")
        return False
    except Exception as e:
        logger.error(f"Error sending prompt to Kiro AI: {e}")
        return False


def prompt_kiro_ai_alternative(prompt: str) -> bool:
    """Alternative method: Use mouse clicking to target the chat input field.
    
    This method:
    1. Opens the chat panel
    2. Uses mouse coordinates or better element finding to click the input
    3. Types the prompt
    
    Args:
        prompt: The prompt text to send
        
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info("Trying alternative method: mouse clicking chat input area")
        
        # Focus Kiro first
        focus_script = 'tell application "Kiro" to activate'
        subprocess.run(
            ["osascript", "-e", focus_script],
            capture_output=True,
            timeout=5
        )
        time.sleep(0.8)  # Wait for app to focus
        
        # Check if chat is already open before opening it
        chat_already_open = _is_chat_open()
        if not chat_already_open:
            # Open chat with Cmd+L only if not already open
            logger.info("Opening chat panel with Cmd+L (alternative method)")
            open_chat_script = '''
            tell application "System Events"
                tell process "Kiro"
                    set frontmost to true
                    delay 0.3
                    -- Open chat with Cmd+L
                    keystroke "l" using command down
                    delay 1.0
                end tell
            end tell
            '''
            
            open_chat_result = subprocess.run(
                ["osascript", "-e", open_chat_script],
                capture_output=True,
                timeout=10
            )
            
            time.sleep(0.8)  # Wait for chat to open
        else:
            logger.info("Chat panel already open, skipping Cmd+L (alternative method)")
            time.sleep(0.3)  # Small delay to ensure UI is ready
        
        # Enhanced method: Find input field by searching through all UI elements
        # Look for text fields, text areas, or scroll areas that contain input fields
        find_and_click_script = '''
        tell application "System Events"
            tell process "Kiro"
                set frontmost to true
                delay 0.3
                set clickedField to false
                try
                    -- Strategy 1: Look for text fields with specific accessibility attributes
                    set allTextFields to every text field
                    set allTextAreas to every text area
                    set allElements to allTextFields & allTextAreas
                    
                    -- Try to find the input field by checking descriptions and values
                    repeat with element in allElements
                        try
                            set elementDesc to description of element as string
                            set elementValue to value of element as string
                            
                            -- Look for input-like elements (empty or with placeholder text)
                            if elementValue is "" or elementDesc contains "input" or elementDesc contains "question" or elementDesc contains "task" or elementDesc contains "describe" then
                                set elementPosition to position of element
                                set elementSize to size of element
                                
                                -- Click on the center of the element
                                set clickX to (item 1 of elementPosition) + (item 1 of elementSize) / 2
                                set clickY to (item 2 of elementPosition) + (item 2 of elementSize) / 2
                                
                                click at {clickX, clickY}
                                delay 0.5
                                set clickedField to true
                                exit repeat
                            end if
                        end try
                    end repeat
                    
                    -- Strategy 2: If found elements but didn't click, click the last one (usually the input)
                    if not clickedField and (count of allElements) > 0 then
                        set lastElement to item -1 of allElements
                        set elementPosition to position of lastElement
                        set elementSize to size of lastElement
                        set clickX to (item 1 of elementPosition) + (item 1 of elementSize) / 2
                        set clickY to (item 2 of elementPosition) + (item 2 of elementSize) / 2
                        click at {clickX, clickY}
                        delay 0.5
                        set clickedField to true
                    end if
                    
                    -- Strategy 3: Use mouse coordinates - typically input is in bottom-right area
                    -- Get window size and click in bottom area where input usually is
                    if not clickedField then
                        set windowBounds to bounds of window 1
                        set windowWidth to (item 3 of windowBounds) - (item 1 of windowBounds)
                        set windowHeight to (item 4 of windowBounds) - (item 2 of windowBounds)
                        
                        -- Click in bottom-right area (where chat input typically is)
                        set clickX to (item 1 of windowBounds) + windowWidth * 0.75
                        set clickY to (item 2 of windowBounds) + windowHeight * 0.85
                        click at {clickX, clickY}
                        delay 0.5
                    end if
                    
                on error errMsg
                    -- Fallback: Just click in bottom area
                    try
                        set windowBounds to bounds of window 1
                        set windowWidth to (item 3 of windowBounds) - (item 1 of windowBounds)
                        set windowHeight to (item 4 of windowBounds) - (item 2 of windowBounds)
                        set clickX to (item 1 of windowBounds) + windowWidth * 0.75
                        set clickY to (item 2 of windowBounds) + windowHeight * 0.85
                        click at {clickX, clickY}
                        delay 0.5
                    end try
                end try
            end tell
        end tell
        '''
        
        click_result = subprocess.run(
            ["osascript", "-e", find_and_click_script],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if click_result.returncode != 0:
            logger.warning(f"Clicking failed: {click_result.stderr}")
        
        time.sleep(0.2)  # Reduced from 0.5s
        
        # Now try typing
        escaped_prompt = (
            prompt
            .replace('\\', '\\\\')
            .replace('"', '\\"')
            .replace('\n', '\\n')
            .replace('\r', '\\r')
        )
        
        type_script = f'''
        tell application "System Events"
            tell process "Kiro"
                set frontmost to true
                delay 0.2
                -- Clear any existing text first
                keystroke "a" using command down
                delay 0.1
                key code 51
                delay 0.1
                -- Type the prompt
                keystroke "{escaped_prompt}"
                delay 0.2
                -- Send with Enter
                key code 36
            end tell
        end tell
        '''
        
        result = subprocess.run(
            ["osascript", "-e", type_script],
            capture_output=True,
            text=True,
            timeout=15
        )
        
        if result.returncode == 0:
            logger.info("Alternative method succeeded")
            # Wait longer for Kiro to process the prompt
            logger.info("Waiting for Kiro to process prompt...")
            time.sleep(3.0)  # Increased wait time to ensure prompt is processed
            return True
        else:
            logger.error(f"Alternative method failed: {result.stderr}")
            return False
        
    except Exception as e:
        logger.error(f"Error with alternative method: {e}")
        return False


def open_inline_chat() -> bool:
    """Open inline chat in Kiro using Cmd+I.
    
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info("Opening inline chat in Kiro")
        return _send_kiro_shortcut("i", command=True)
    except Exception as e:
        logger.error(f"Error opening inline chat: {e}")
        return False


def show_all_commands() -> bool:
    """Show all commands palette in Kiro using Shift+Cmd+P.
    
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info("Showing all commands in Kiro")
        return _send_kiro_shortcut("p", command=True, shift=True)
    except Exception as e:
        logger.error(f"Error showing all commands: {e}")
        return False


def go_to_file() -> bool:
    """Open Go to File dialog in Kiro using Cmd+P.
    
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info("Opening Go to File dialog in Kiro")
        return _send_kiro_shortcut("p", command=True)
    except Exception as e:
        logger.error(f"Error opening Go to File: {e}")
        return False


def find_in_files() -> bool:
    """Open Find in Files dialog in Kiro using Shift+Cmd+F.
    
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info("Opening Find in Files dialog in Kiro")
        return _send_kiro_shortcut("f", command=True, shift=True)
    except Exception as e:
        logger.error(f"Error opening Find in Files: {e}")
        return False


def start_debugging() -> bool:
    """Start debugging in Kiro using F5.
    
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info("Starting debugging in Kiro")
        # F5 key code is 96
        return _send_kiro_keycode(96)
    except Exception as e:
        logger.error(f"Error starting debugging: {e}")
        return False


def toggle_terminal() -> bool:
    """Toggle terminal in Kiro using Shift+` (backtick).
    
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info("Toggling terminal in Kiro")
        return _send_kiro_shortcut("`", shift=True)
    except Exception as e:
        logger.error(f"Error toggling terminal: {e}")
        return False


def toggle_full_screen() -> bool:
    """Toggle full screen in Kiro using Shift+Cmd+F.
    
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info("Toggling full screen in Kiro")
        return _send_kiro_shortcut("f", command=True, shift=True)
    except Exception as e:
        logger.error(f"Error toggling full screen: {e}")
        return False


def show_settings() -> bool:
    """Show settings in Kiro using Cmd+, (comma).
    
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info("Showing settings in Kiro")
        return _send_kiro_shortcut(",", command=True)
    except Exception as e:
        logger.error(f"Error showing settings: {e}")
        return False


def _is_kiro_frontmost() -> bool:
    """Check if Kiro is currently the frontmost application.
    
    Returns:
        True if Kiro is frontmost, False otherwise
    """
    try:
        script = '''
        tell application "System Events"
            set frontApp to name of first application process whose frontmost is true
            return frontApp is "Kiro"
        end tell
        '''
        
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode == 0:
            return result.stdout.strip().lower() == "true"
        return False
        
    except Exception as e:
        logger.error(f"Error checking if Kiro is frontmost: {e}")
        return False


def _is_chat_open() -> bool:
    """Check if Kiro chat panel is already open.
    
    Returns:
        True if chat is open, False otherwise
    """
    try:
        script = '''
        tell application "System Events"
            tell process "Kiro"
                try
                    -- Look for text fields that indicate chat is open
                    set textFields to every text field
                    if (count of textFields) > 0 then
                        -- Check if any text field looks like a chat input
                        repeat with textField in textFields
                            try
                                set fieldDesc to description of textField as string
                                if fieldDesc contains "input" or fieldDesc contains "question" or fieldDesc contains "task" or fieldDesc contains "chat" then
                                    return true
                                end if
                            end try
                        end repeat
                        -- If we have text fields, chat might be open
                        return true
                    end if
                    return false
                on error
                    return false
                end try
            end tell
        end tell
        '''
        
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode == 0:
            return result.stdout.strip().lower() == "true"
        return False
        
    except Exception as e:
        logger.debug(f"Error checking if chat is open: {e}")
        return False


def switch_to_kiro_with_option_tab() -> bool:
    """Switch to Kiro using Option+Tab (macOS app switcher).
    
    This is useful when you don't want to force focus on Kiro
    or when the chat input field detection is unreliable.
    Option+Tab works at system level, so it doesn't require Kiro to be focused first.
    
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info("Switching to Kiro using Option+Tab")
        
        # Option+Tab works at system level, not through Kiro process
        # Tab key code is 48
        script = '''
        tell application "System Events"
            key code 48 using option down
            delay 0.3
        end tell
        '''
        
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode == 0:
            time.sleep(0.5)  # Wait for app switch to complete
            return True
        return False
        
    except Exception as e:
        logger.error(f"Error switching with Option+Tab: {e}")
        return False


def _send_kiro_shortcut(key: str, command: bool = False, shift: bool = False, control: bool = False, option: bool = False) -> bool:
    """Helper function to send a keyboard shortcut to Kiro.
    
    Args:
        key: The key to press (e.g., "p", "f", "`", ",")
        command: Whether to hold Command key
        shift: Whether to hold Shift key
        control: Whether to hold Control key
        option: Whether to hold Option key
        
    Returns:
        True if successful, False otherwise
    """
    try:
        # Focus Kiro first
        focus_script = 'tell application "Kiro" to activate'
        subprocess.run(
            ["osascript", "-e", focus_script],
            capture_output=True,
            timeout=5
        )
        time.sleep(0.2)  # Reduced from 0.3s
        
        # Build the modifier string
        modifiers = []
        if command:
            modifiers.append("command down")
        if shift:
            modifiers.append("shift down")
        if control:
            modifiers.append("control down")
        if option:
            modifiers.append("option down")
        
        modifier_str = " using " + " ".join(modifiers) if modifiers else ""
        
        # Escape special characters for AppleScript
        escaped_key = key.replace('\\', '\\\\').replace('"', '\\"')
        
        script = f'''
        tell application "System Events"
            tell process "Kiro"
                set frontmost to true
                delay 0.2
                keystroke "{escaped_key}"{modifier_str}
            end tell
        end tell
        '''
        
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        return result.returncode == 0
        
    except Exception as e:
        logger.error(f"Error sending shortcut: {e}")
        return False


def _send_kiro_keycode(keycode: int, command: bool = False, shift: bool = False, control: bool = False, option: bool = False) -> bool:
    """Helper function to send a key code to Kiro.
    
    Args:
        keycode: The key code to press (e.g., 96 for F5)
        command: Whether to hold Command key
        shift: Whether to hold Shift key
        control: Whether to hold Control key
        option: Whether to hold Option key
        
    Returns:
        True if successful, False otherwise
    """
    try:
        # Focus Kiro first
        focus_script = 'tell application "Kiro" to activate'
        subprocess.run(
            ["osascript", "-e", focus_script],
            capture_output=True,
            timeout=5
        )
        time.sleep(0.2)  # Reduced from 0.3s
        
        # Build the modifier string
        modifiers = []
        if command:
            modifiers.append("command down")
        if shift:
            modifiers.append("shift down")
        if control:
            modifiers.append("control down")
        if option:
            modifiers.append("option down")
        
        modifier_str = " using " + " ".join(modifiers) if modifiers else ""
        
        script = f'''
        tell application "System Events"
            tell process "Kiro"
                set frontmost to true
                delay 0.2
                key code {keycode}{modifier_str}
            end tell
        end tell
        '''
        
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        return result.returncode == 0
        
    except Exception as e:
        logger.error(f"Error sending keycode: {e}")
        return False


def wait_for_kiro_completion(repo_path: Optional[str] = None, timeout: int = 30, expected_files: Optional[list] = None) -> bool:
    """Wait for Kiro.app to complete work after receiving a prompt.
    
    This function waits for Kiro.app to finish generating code/files. It can:
    1. Wait for specific expected files to be created
    2. Wait a reasonable time for Kiro.app to process
    3. Poll for common project files (package.json, etc.)
    
    Args:
        repo_path: Repository path to check for files (optional)
        timeout: Maximum time to wait in seconds (default: 30)
        expected_files: List of file paths to wait for (optional)
        
    Returns:
        True if completion detected or timeout reached (non-blocking), False on error
    """
    try:
        logger.info(f"Waiting for Kiro.app to complete work (timeout: {timeout}s)")
        
        # If expected files are provided, wait for them
        if expected_files and repo_path:
            from actions.file_actions import wait_for_any_file
            
            # Make paths absolute if repo_path is provided
            full_paths = [
                os.path.join(repo_path, f) if not os.path.isabs(f) else f
                for f in expected_files
            ]
            
            found, file_path = wait_for_any_file(full_paths, timeout=timeout)
            if found:
                logger.info(f"Kiro.app completion detected: {file_path} created")
                return True
        
        # Otherwise, wait a reasonable time for Kiro.app to process
        # Kiro.app typically takes 5-15 seconds to generate code
        # Increased wait time to ensure proper completion
        wait_time = min(timeout, 12)  # Increased from 8s to 12s for default wait
        logger.info(f"Waiting {wait_time}s for Kiro.app to process...")
        time.sleep(wait_time)
        
        # If repo_path is provided, check for common project files
        if repo_path:
            common_files = [
                "package.json",
                "package-lock.json",
                "yarn.lock",
                "requirements.txt",
                "Pipfile",
                ".gitignore"
            ]
            
            for common_file in common_files:
                file_path = os.path.join(repo_path, common_file)
                if os.path.exists(file_path):
                    logger.info(f"Detected project file: {common_file}")
                    return True
        
        logger.info("Kiro.app work completion wait finished")
        return True
        
    except Exception as e:
        logger.error(f"Error waiting for Kiro.app completion: {e}")
        return False

