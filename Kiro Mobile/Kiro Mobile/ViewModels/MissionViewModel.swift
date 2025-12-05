//
//  MissionViewModel.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import Foundation
import SwiftUI

@MainActor
class MissionViewModel: ObservableObject {
    @Published var missions: [Mission] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedMission: Mission?
    
    private let apiService: APIServiceProtocol
    private let storageService: StorageServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(
        apiService: APIServiceProtocol,
        storageService: StorageServiceProtocol,
        authService: AuthServiceProtocol
    ) {
        self.apiService = apiService
        self.storageService = storageService
        self.authService = authService
    }
    
    func loadMissions() async {
        isLoading = true
        errorMessage = nil
        
        // Load cached missions first
        missions = storageService.loadCachedMissions()
        
        do {
            // Try to fetch from API
            // Note: We don't have a list endpoint, so we'll work with cached missions
            // In a real app, you'd have GET /missions endpoint
            isLoading = false
        } catch {
            errorMessage = "Failed to load missions: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func createMission(prompt: String, repoPath: String) async -> Bool {
        guard let username = authService.getUsername() else {
            errorMessage = "Please set your username in settings"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        let settings = storageService.loadSettings()
        let macId = settings.macId
        
        do {
            let response = try await apiService.createMission(
                user: username,
                prompt: prompt,
                repoPath: repoPath,
                macId: macId
            )
            
            // Fetch the full mission
            let mission = try await apiService.getMission(id: response.missionId)
            
            missions.insert(mission, at: 0)
            storageService.cacheMissions(missions)
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to create mission: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func refreshMission(_ mission: Mission) async {
        do {
            let updated = try await apiService.getMission(id: mission.id)
            if let index = missions.firstIndex(where: { $0.id == mission.id }) {
                missions[index] = updated
                storageService.cacheMissions(missions)
            }
            if selectedMission?.id == mission.id {
                selectedMission = updated
            }
        } catch {
            errorMessage = "Failed to refresh mission: \(error.localizedDescription)"
        }
    }
    
    func deleteMission(_ mission: Mission) async {
        do {
            try await apiService.deleteMission(id: mission.id)
            missions.removeAll { $0.id == mission.id }
            storageService.cacheMissions(missions)
            if selectedMission?.id == mission.id {
                selectedMission = nil
            }
        } catch {
            errorMessage = "Failed to delete mission: \(error.localizedDescription)"
        }
    }
}


