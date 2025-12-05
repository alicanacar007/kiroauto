//
//  APIModels.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import Foundation

// MARK: - Request Models

struct MissionCreateRequest: Codable {
    let user: String
    let prompt: String
    let repoPath: String
    let macId: String
    
    enum CodingKeys: String, CodingKey {
        case user
        case prompt
        case repoPath = "repo_path"
        case macId = "mac_id"
    }
}

struct EventRequest: Codable {
    let macId: String
    let stepId: String
    let status: String
    let stdout: String?
    let stderr: String?
    let screenshots: [String]?
    
    enum CodingKeys: String, CodingKey {
        case macId = "mac_id"
        case stepId = "step_id"
        case status
        case stdout
        case stderr
        case screenshots
    }
}

// MARK: - Response Models

struct MissionCreateResponse: Codable {
    let missionId: String
    let plan: Plan
    
    enum CodingKeys: String, CodingKey {
        case missionId = "mission_id"
        case plan
    }
}

struct EventResponse: Codable {
    let ok: Bool
    let eventId: String
    
    enum CodingKeys: String, CodingKey {
        case ok
        case eventId = "event_id"
    }
}
