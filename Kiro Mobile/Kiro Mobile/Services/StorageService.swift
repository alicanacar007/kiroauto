//
//  StorageService.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import Foundation
import Combine
import SwiftUI

protocol StorageServiceProtocol {
    func saveSettings(_ settings: AppSettings)
    func loadSettings() -> AppSettings
    func cacheMissions(_ missions: [Mission])
    func loadCachedMissions() -> [Mission]
    func clearCache()
}

class StorageService: ObservableObject, StorageServiceProtocol {
    private let defaults = UserDefaults.standard
    private let cacheKey = "cached_missions"
    private let settingsKey = "app_settings"
    
    func saveSettings(_ settings: AppSettings) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let encoded = try? encoder.encode(settings) {
            defaults.set(encoded, forKey: settingsKey)
        }
    }
    
    func loadSettings() -> AppSettings {
        guard let data = defaults.data(forKey: settingsKey) else {
            return AppSettings.default
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return AppSettings.default
        }
        return settings
    }
    
    func cacheMissions(_ missions: [Mission]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let encoded = try? encoder.encode(missions) {
            defaults.set(encoded, forKey: cacheKey)
        }
    }
    
    func loadCachedMissions() -> [Mission] {
        guard let data = defaults.data(forKey: cacheKey) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let missions = try? decoder.decode([Mission].self, from: data) else {
            return []
        }
        return missions
    }
    
    func clearCache() {
        defaults.removeObject(forKey: cacheKey)
    }
}
