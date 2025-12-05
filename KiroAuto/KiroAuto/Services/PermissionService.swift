//
//  PermissionService.swift
//  KiroAuto
//
//  Created by Ali Can Acar on 12/5/25.
//

import Foundation
import AppKit

class PermissionService: ObservableObject {
    @Published var hasAccessibilityPermission = false
    
    init() {
        // Check permission status on initialization
        _ = checkAccessibilityPermission()
    }
    
    func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        DispatchQueue.main.async {
            self.hasAccessibilityPermission = accessEnabled
        }
        
        return accessEnabled
    }
    
    func openAccessibilitySettings() {
        // Use the modern System Settings URL for macOS 13+
        if #available(macOS 13.0, *) {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        } else {
            // Fallback for older macOS versions
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
    
    func requestAccessibilityPermission() {
        // Request permission with prompt - this will show the system dialog
        // and add the app to the Accessibility list if it's not there
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        DispatchQueue.main.async {
            self.hasAccessibilityPermission = accessEnabled
        }
        
        // If permission was denied, open settings after a short delay
        if !accessEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.openAccessibilitySettings()
            }
        }
    }
}
