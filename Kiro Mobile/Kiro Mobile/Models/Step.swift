//
//  Step.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import Foundation

struct Step: Codable, Identifiable, Equatable {
    let stepId: String
    let title: String
    let actions: [Action]
    let expectMarker: String?
    var status: StepStatus
    var logs: StepLogs?
    
    var id: String { stepId }
    
    enum CodingKeys: String, CodingKey {
        case stepId = "step_id"
        case title
        case actions
        case expectMarker = "expect_marker"
        case status
        case logs
    }
}

enum StepStatus: String, Codable, Equatable {
    case pending
    case running
    case completed
    case failed
    case stalled
}

struct StepLogs: Codable, Equatable {
    let stdout: String?
    let stderr: String?
    let screenshots: [String]?
}
