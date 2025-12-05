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
    
    init(stepId: String, title: String, actions: [Action], expectMarker: String?, status: StepStatus = .pending, logs: StepLogs? = nil) {
        self.stepId = stepId
        self.title = title
        self.actions = actions
        self.expectMarker = expectMarker
        self.status = status
        self.logs = logs
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stepId = try container.decode(String.self, forKey: .stepId)
        title = try container.decode(String.self, forKey: .title)
        actions = try container.decode([Action].self, forKey: .actions)
        expectMarker = try container.decodeIfPresent(String.self, forKey: .expectMarker)
        status = try container.decodeIfPresent(StepStatus.self, forKey: .status) ?? .pending
        logs = try container.decodeIfPresent(StepLogs.self, forKey: .logs)
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
