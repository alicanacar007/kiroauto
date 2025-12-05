//
//  AutomationService.swift
//  KiroAuto
//
//  Created by Ali Can Acar on 12/5/25.
//

import Foundation
import AppKit

class AutomationService {
    // State tracking to prevent duplicate actions
    private var lastPrompt: String? = nil
    private var lastPromptTime: Date? = nil
    private var chatOpenState: Bool = false
    
    func executeAction(_ action: Action, repoPath: String) async -> (success: Bool, output: String) {
        switch action.type {
        case "open_app":
            return await openApp(action.app ?? "")
        case "open_project":
            return await openProject(action.path ?? repoPath)
        case "run_command":
            return await runCommand(action.cmd ?? "", in: repoPath)
        case "prompt_kiro_ai":
            return await promptKiroAI(action.prompt ?? "")
        case "screenshot":
            return await takeScreenshot()
        case "wait_for_marker":
            return await waitForMarker(action.marker ?? "")
        default:
            return (false, "Unknown action type: \(action.type)")
        }
    }
    
    private func openApp(_ appName: String) async -> (Bool, String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-a", appName]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // Reduced from 2s to 1s
                return (true, "Opened \(appName)")
            } else {
                return (false, "Failed to open \(appName)")
            }
        } catch {
            return (false, "Error opening \(appName): \(error.localizedDescription)")
        }
    }
    
    private func runCommand(_ command: String, in directory: String) async -> (Bool, String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-l", "-c", command] // -l loads user's profile with PATH
        process.currentDirectoryURL = URL(fileURLWithPath: directory)
        
        // Set environment with common paths
        var environment = ProcessInfo.processInfo.environment
        let commonPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/usr/bin",
            "/bin",
            environment["PATH"] ?? ""
        ].joined(separator: ":")
        environment["PATH"] = commonPaths
        process.environment = environment
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""
            
            let success = process.terminationStatus == 0
            let result = output + (error.isEmpty ? "" : "\nError: \(error)")
            
            return (success, result)
        } catch {
            return (false, "Failed to run command: \(error.localizedDescription)")
        }
    }
    
    private func openProject(_ path: String) async -> (Bool, String) {
        // Use AppleScript to open folder in Kiro
        let script = """
        tell application "Kiro"
            activate
            open "\(path)"
        end tell
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: errorData, encoding: .utf8) ?? ""
            
            if process.terminationStatus == 0 {
                try? await Task.sleep(nanoseconds: 500_000_000) // Reduced from 1s to 0.5s
                return (true, "Opened project: \(path)")
            } else {
                return (false, "Failed to open project: \(error)")
            }
        } catch {
            return (false, "Error opening project: \(error.localizedDescription)")
        }
    }
    
    private func isChatOpen() async -> Bool {
        let script = """
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
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            
            return output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
        } catch {
            return false
        }
    }
    
    private func promptKiroAI(_ prompt: String) async -> (Bool, String) {
        // Check for duplicate prompts (same prompt within 2 seconds)
        let currentTime = Date()
        if let lastPrompt = lastPrompt, let lastTime = lastPromptTime,
           prompt == lastPrompt, currentTime.timeIntervalSince(lastTime) < 2.0 {
            return (true, "Duplicate prompt detected, skipping")
        }
        
        lastPrompt = prompt
        lastPromptTime = currentTime
        
        // First, ensure Kiro is focused
        let focusScript = """
        tell application "Kiro"
            activate
        end tell
        """
        
        let focusProcess = Process()
        focusProcess.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        focusProcess.arguments = ["-e", focusScript]
        
        do {
            try focusProcess.run()
            focusProcess.waitUntilExit()
            // Wait for Kiro to come to front
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        } catch {
            // Continue anyway, might already be focused
        }
        
        // Check if chat is already open before opening it
        let chatAlreadyOpen = await isChatOpen()
        var openChatScript = ""
        
        if chatAlreadyOpen {
            // Chat is already open, skip Cmd+L
            openChatScript = """
            tell application "System Events"
                tell process "Kiro"
                    set frontmost to true
                    delay 0.3
                end tell
            end tell
            """
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        } else {
            // Open chat with Cmd+L
            openChatScript = """
            tell application "System Events"
                tell process "Kiro"
                    set frontmost to true
                    delay 0.5
                    -- Open chat with Cmd+L
                    keystroke "l" using command down
                    delay 1.0
                end tell
            end tell
            """
            
            let openProcess = Process()
            openProcess.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            openProcess.arguments = ["-e", openChatScript]
            
            do {
                try openProcess.run()
                openProcess.waitUntilExit()
            } catch {
                // Continue anyway
            }
            
            try? await Task.sleep(nanoseconds: 800_000_000) // Wait for chat to open
            chatOpenState = true
        }
        
        // Use AppleScript to send prompt to Kiro AI
        // Escape special characters for AppleScript
        let escapedPrompt = prompt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        
        let script = """
        tell application "System Events"
            tell process "Kiro"
                set frontmost to true
                delay 0.3
                -- Clear any existing text first (Cmd+A then delete)
                keystroke "a" using command down
                delay 0.1
                key code 51
                delay 0.1
                -- Type the prompt
                keystroke "\(escapedPrompt)"
                delay 0.3
                -- Send with Enter
                key code 36
                delay 0.3
            end tell
        end tell
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: errorData, encoding: .utf8) ?? ""
            
            if process.terminationStatus == 0 {
                // Wait longer for Kiro to process the prompt before allowing next action
                try? await Task.sleep(nanoseconds: 3_000_000_000) // Increased to 3 seconds
                
                // After waiting, check for and click any action buttons that appear
                // (e.g., "Move to design phase", "Continue", etc.)
                let buttonClicked = await clickKiroActionButtons()
                if buttonClicked {
                    return (true, "Sent prompt to Kiro AI: \(prompt) and clicked action button")
                }
                
                return (true, "Sent prompt to Kiro AI: \(prompt)")
            } else {
                return (false, "Failed to send prompt: \(error)")
            }
        } catch {
            return (false, "Error sending prompt: \(error.localizedDescription)")
        }
    }
    
    private func waitForMarker(_ marker: String) async -> (Bool, String) {
        // Wait for a specific marker/checkpoint
        // Increased wait time to ensure proper synchronization
        try? await Task.sleep(nanoseconds: 2_000_000_000) // Increased to 2s for better sync
        return (true, "Waited for marker: \(marker)")
    }
    
    private func takeScreenshot() async -> (Bool, String) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "screenshot_\(timestamp).png"
        let desktopPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").path
        let fullPath = "\(desktopPath)/\(filename)"
        
        let script = """
        screencapture -x "\(fullPath)"
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                return (true, "Screenshot saved: \(filename)")
            } else {
                return (false, "Failed to capture screenshot")
            }
        } catch {
            return (false, "Error capturing screenshot: \(error.localizedDescription)")
        }
    }
    
    /// Detects and clicks action buttons that appear in Kiro after AI completes work
    /// Common buttons: "Move to design phase", "Continue", "Next", etc.
    /// Retries up to 3 times with increasing delays to catch buttons that appear later
    private func clickKiroActionButtons() async -> Bool {
        // Try multiple times with increasing delays - buttons may appear after different processing times
        for attempt in 1...3 {
            let delaySeconds = Double(attempt) * 1.5 // 1.5s, 3s, 4.5s
            try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            
            let script = """
            tell application "System Events"
                tell process "Kiro"
                    set frontmost to true
                    delay 0.3
                    
                    try
                        -- Look for buttons with common action text
                        set buttonTexts to {"Move to design phase", "Move to", "design phase", "Continue", "Next", "Proceed", "Accept", "Done", "OK", "Apply", "Confirm"}
                        set foundButton to false
                        
                        -- Strategy 1: Find buttons by exact name/title
                        repeat with buttonText in buttonTexts
                            try
                                set buttons to every button whose name contains buttonText
                                if (count of buttons) > 0 then
                                    click (item 1 of buttons)
                                    delay 0.3
                                    set foundButton to true
                                    exit repeat
                                end if
                            end try
                        end repeat
                        
                        -- Strategy 2: Find buttons by value/description (case-insensitive)
                        if not foundButton then
                            repeat with buttonText in buttonTexts
                                try
                                    set allButtons to every button
                                    repeat with btn in allButtons
                                        try
                                            if enabled of btn is true then
                                                set btnValue to value of btn as string
                                                set btnDesc to description of btn as string
                                                set btnName to name of btn as string
                                                
                                                -- Case-insensitive check
                                                if btnValue contains buttonText or btnDesc contains buttonText or btnName contains buttonText then
                                                    click btn
                                                    delay 0.3
                                                    set foundButton to true
                                                    exit repeat
                                                end if
                                            end if
                                        end try
                                    end repeat
                                    if foundButton then exit repeat
                                end try
                            end repeat
                        end if
                        
                        -- Strategy 3: Find visible enabled buttons in the main window area
                        -- (action buttons are usually prominently displayed)
                        if not foundButton then
                            try
                                set mainWindow to window 1
                                set windowButtons to every button of mainWindow
                                repeat with btn in windowButtons
                                    try
                                        if enabled of btn is true and visible of btn is true then
                                            set btnBounds to bounds of btn
                                            -- Check if button is in visible area and reasonably sized
                                            if item 2 of btnBounds > 100 and item 2 of btnBounds < 1500 and (item 3 of btnBounds) - (item 1 of btnBounds) > 50 then
                                                click btn
                                                delay 0.3
                                                set foundButton to true
                                                exit repeat
                                            end if
                                        end if
                                    end try
                                end repeat
                            end try
                        end if
                        
                        return foundButton
                    on error
                        return false
                    end try
                end tell
            end tell
            """
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8) ?? ""
                
                // Check if button was clicked
                if process.terminationStatus == 0 {
                    // AppleScript returns "true" or "false" as string
                    if output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true" {
                        return true
                    }
                }
            } catch {
                // Continue to next attempt
            }
        }
        
        return false
    }
}
