//
//  Plan.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import Foundation

struct Plan: Codable, Equatable {
    let missionId: String
    let plan: [Step]
    
    enum CodingKeys: String, CodingKey {
        case missionId = "mission_id"
        case plan
    }
}
