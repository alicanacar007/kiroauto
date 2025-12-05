//
//  MissionViewModel.swift
//  KiroAuto
//
//  Created by Ali Can Acar on 12/5/25.
//

import Foundation

@MainActor
class MissionViewModel: ObservableObject {
    @Published var currentMission: Mission?
    @Published var isRunning = false
    @Published var logs: [String] = []
    @Published var currentStep: Step?
    
    private let backendService = BackendService()
    private let automationService = AutomationService()
    private var pollingTask: Task<Void, Never>?
    
    func createMission(user: String, prompt: String, repoPath: String) async {
        do {
            addLog("Creating mission...")
            let response = try await backendService.createMission(user: user, prompt: prompt, repoPath: repoPath)
            addLog("Mission created: \(response.missionId)")
            
            // Fetch full mission details
            let mission = try await backendService.getMission(missionId: response.missionId)
            currentMission = mission
            addLog("Mission loaded with \(mission.plan.plan.count) steps")
        } catch {
            addLog("Error creating mission: \(error.localizedDescription)")
        }
    }
    
    func startMission() {
        guard let mission = currentMission else { return }
        isRunning = true
        addLog("Starting mission execution...")
        
        pollingTask = Task {
            await executeMissionLoop(missionId: mission.id, repoPath: mission.repoPath)
        }
    }
    
    func stopMission() {
        isRunning = false
        pollingTask?.cancel()
        addLog("Mission stopped")
    }
    
    private func executeMissionLoop(missionId: String, repoPath: String) async {
        var consecutiveEmptyPolls = 0
        let maxEmptyPolls = 3 // After 3 empty polls, increase interval
        
        while isRunning {
            do {
                // Get next step
                guard let step = try await backendService.getNextStep(missionId: missionId) else {
                    consecutiveEmptyPolls += 1
                    
                    if consecutiveEmptyPolls >= maxEmptyPolls {
                        addLog("No more steps - mission complete!")
                        isRunning = false
                        break
                    }
                    
                    // Adaptive wait: longer when no steps available
                    let waitTime = UInt64(consecutiveEmptyPolls) * 2_000_000_000 // 2s, 4s, 6s
                    try? await Task.sleep(nanoseconds: waitTime)
                    continue
                }
                
                // Reset empty poll counter when we get a step
                consecutiveEmptyPolls = 0
                
                currentStep = step
                addLog("Executing step: \(step.stepId) - \(step.title)")
                
                // Report step started
                try await backendService.postEvent(missionId: missionId, stepId: step.stepId, status: "running")
                
                // Execute actions
                var allSuccess = true
                var outputs: [String] = []
                
                for (index, action) in step.actions.enumerated() {
                    // Log action details
                    var actionDetail = "  [\(index + 1)/\(step.actions.count)] \(action.type)"
                    if let app = action.app {
                        actionDetail += " → \(app)"
                    }
                    if let cmd = action.cmd {
                        actionDetail += " → \(cmd)"
                    }
                    if let prompt = action.prompt {
                        actionDetail += " → \"\(prompt)\""
                    }
                    if let path = action.path {
                        actionDetail += " → \(path)"
                    }
                    addLog(actionDetail)
                    
                    let (success, output) = await automationService.executeAction(action, repoPath: repoPath)
                    outputs.append(output)
                    
                    if !success {
                        allSuccess = false
                        addLog("  ❌ Failed: \(output)")
                        break
                    } else {
                        addLog("  ✅ Success: \(output)")
                    }
                    
                    // Add extra delay after prompt_kiro_ai to prevent "Execution Queued" errors
                    // The promptKiroAI function already waits 3 seconds, but add a bit more
                    // to ensure Kiro has fully processed the prompt before next action
                    if action.type == "prompt_kiro_ai" {
                        addLog("  ⏳ Waiting for Kiro to process prompt...")
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // Additional 2 seconds for better sync
                    }
                }
                
                // Report step completed
                let status = allSuccess ? "completed" : "failed"
                let stdout = outputs.joined(separator: "\n")
                try await backendService.postEvent(missionId: missionId, stepId: step.stepId, status: status, stdout: stdout)
                
                addLog("Step \(step.stepId) \(status)")
                
                // Reduced wait time after step completion
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second (reduced from 3)
                
            } catch {
                addLog("Error: \(error.localizedDescription)")
                // Exponential backoff on errors
                let backoffTime = min(UInt64(5_000_000_000), UInt64(1_000_000_000) * UInt64(consecutiveEmptyPolls + 1))
                try? await Task.sleep(nanoseconds: backoffTime)
            }
        }
    }
    
    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logs.append("[\(timestamp)] \(message)")
    }
}
