//
//  BackendService.swift
//  KiroAuto
//
//  Created by Ali Can Acar on 12/5/25.
//

import Foundation

class BackendService: ObservableObject {
    private let baseURL = "http://127.0.0.1:5757"
    private let macId = "mac-01"
    
    @Published var isBackendOnline: Bool = false
    @Published var backendStatusMessage: String = "Checking..."
    
    private var statusCheckTask: Task<Void, Never>?
    private var consecutiveFailures: Int = 0
    private let maxPollInterval: UInt64 = 30_000_000_000 // 30 seconds max
    private let minPollInterval: UInt64 = 10_000_000_000 // 10 seconds min (increased from 5)
    
    init() {
        startStatusChecking()
    }
    
    deinit {
        statusCheckTask?.cancel()
    }
    
    func startStatusChecking() {
        // Check immediately
        Task {
            await checkBackendStatus()
        }
        
        // Then check periodically with adaptive interval
        statusCheckTask = Task {
            while !Task.isCancelled {
                // Adaptive polling: longer intervals when offline, shorter when online
                let interval = await MainActor.run {
                    if self.isBackendOnline {
                        // Backend is online: check every 10 seconds
                        self.consecutiveFailures = 0
                        return self.minPollInterval
                    } else {
                        // Backend is offline: exponential backoff up to 30 seconds
                        self.consecutiveFailures += 1
                        let backoffInterval = min(
                            self.minPollInterval * UInt64(1 << min(self.consecutiveFailures, 2)),
                            self.maxPollInterval
                        )
                        return backoffInterval
                    }
                }
                
                try? await Task.sleep(nanoseconds: interval)
                await checkBackendStatus()
            }
        }
    }
    
    func checkBackendStatus() async {
        let url = URL(string: "\(baseURL)/")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 1.5 // Reduced from 2.0 seconds
        request.cachePolicy = .reloadIgnoringLocalCacheData // Prevent caching
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    await MainActor.run {
                        self.isBackendOnline = true
                        self.backendStatusMessage = "Connected"
                        self.consecutiveFailures = 0
                    }
                } else {
                    await MainActor.run {
                        self.isBackendOnline = false
                        self.backendStatusMessage = "Error: \(httpResponse.statusCode)"
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.isBackendOnline = false
                self.backendStatusMessage = "Disconnected"
            }
        }
    }
    
    func createMission(user: String, prompt: String, repoPath: String) async throws -> MissionCreateResponse {
        let url = URL(string: "\(baseURL)/missions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = MissionCreateRequest(user: user, prompt: prompt, repoPath: repoPath, macId: macId)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(MissionCreateResponse.self, from: data)
    }
    
    func getMission(missionId: String) async throws -> Mission {
        let url = URL(string: "\(baseURL)/missions/\(missionId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Mission.self, from: data)
    }
    
    func getNextStep(missionId: String) async throws -> Step? {
        let url = URL(string: "\(baseURL)/missions/\(missionId)/next_step?mac_id=\(macId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(NextStepResponse.self, from: data)
        return response.step
    }
    
    func postEvent(missionId: String, stepId: String, status: String, stdout: String? = nil, stderr: String? = nil) async throws {
        let url = URL(string: "\(baseURL)/missions/\(missionId)/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let event = EventRequest(macId: macId, stepId: stepId, status: status, stdout: stdout, stderr: stderr, screenshots: nil)
        request.httpBody = try JSONEncoder().encode(event)
        
        let _ = try await URLSession.shared.data(for: request)
    }
}
