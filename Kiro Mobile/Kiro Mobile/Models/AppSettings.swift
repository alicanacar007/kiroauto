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
    var lastSyncDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case backendURL = "backend_url"
        case macId = "mac_id"
        case lastSyncDate = "last_sync_date"
    }
    
    static let `default` = AppSettings(
        backendURL: "http://localhost:5757",
        macId: "mac-01",
        lastSyncDate: nil
    )
}
