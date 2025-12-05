//
//  Action.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import Foundation

struct Action: Codable, Equatable {
    let type: ActionType
    let app: String?
    let path: String?
    let cmd: String?
    let prompt: String?
    let marker: String?
}

enum ActionType: String, Codable, Equatable {
    case openApp = "open_app"
    case screenshot
    case runCommand = "run_command"
    case kiroPrompt = "kiro_prompt"
    case waitForMarker = "wait_for_marker"
}
