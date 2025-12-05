//
//  Mission.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import Foundation

struct Mission: Codable, Identifiable, Equatable {
    let id: String
    let user: String
    let prompt: String
    let repoPath: String
    let macId: String
    var status: MissionStatus
    let plan: Plan
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case user
        case prompt
        case repoPath = "repo_path"
        case macId = "mac_id"
        case status
        case plan
        case createdAt = "created_at"
    }
}

enum MissionStatus: String, Codable, Equatable {
    case pending
    case running
    case done
    case failed
}
