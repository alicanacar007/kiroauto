//
//  Mission.swift
//  KiroAuto
//
//  Created by Ali Can Acar on 12/5/25.
//

import Foundation

struct Mission: Codable, Identifiable {
    let id: String
    let user: String
    let prompt: String
    let repoPath: String
    let macId: String
    let status: String
    let plan: Plan
    
    enum CodingKeys: String, CodingKey {
        case id, user, prompt, status, plan
        case repoPath = "repo_path"
        case macId = "mac_id"
    }
}

struct Plan: Codable {
    let missionId: String
    let plan: [Step]
    
    enum CodingKeys: String, CodingKey {
        case missionId = "mission_id"
        case plan
    }
}

struct Step: Codable, Identifiable {
    let stepId: String
    let title: String
    let actions: [Action]
    let expectMarker: String?
    
    var id: String { stepId }
    
    enum CodingKeys: String, CodingKey {
        case stepId = "step_id"
        case title, actions
        case expectMarker = "expect_marker"
    }
}

struct Action: Codable {
    let type: String
    let app: String?
    let path: String?
    let cmd: String?
    let prompt: String?
    let marker: String?
}

struct MissionCreateRequest: Codable {
    let user: String
    let prompt: String
    let repoPath: String
    let macId: String
    
    enum CodingKeys: String, CodingKey {
        case user, prompt
        case repoPath = "repo_path"
        case macId = "mac_id"
    }
}

struct MissionCreateResponse: Codable {
    let missionId: String
    let plan: Plan
    
    enum CodingKeys: String, CodingKey {
        case missionId = "mission_id"
        case plan
    }
}

struct NextStepResponse: Codable {
    let step: Step?
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
        case status, stdout, stderr, screenshots
    }
}
