//
//  AppSettings.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import Foundation

struct AppSettings: Codable {
    var backendURL: String
    var macId: String
    var demoRepoPath: String
    var lastSyncDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case backendURL = "backend_url"
        case macId = "mac_id"
        case demoRepoPath = "demo_repo_path"
        case lastSyncDate = "last_sync_date"
    }
    
    static let `default` = AppSettings(
        backendURL: "http://localhost:5757",
        macId: "mac-01",
        demoRepoPath: "/Users/alicanacar/Main Ali/projects2025/testAI",
        lastSyncDate: nil
    )
}
