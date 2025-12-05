//
//  MissionDetailView.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import SwiftUI

struct MissionDetailView: View {
    let mission: Mission
    @ObservedObject var viewModel: MissionViewModel
    @State private var currentMission: Mission
    
    init(mission: Mission, viewModel: MissionViewModel) {
        self.mission = mission
        self.viewModel = viewModel
        _currentMission = State(initialValue: mission)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Mission Header
                VStack(alignment: .leading, spacing: 12) {
                    Text(currentMission.prompt)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Label(currentMission.status.rawValue.capitalized, systemImage: statusIcon(for: currentMission.status))
                            .foregroundColor(statusColor(for: currentMission.status))
                        
                        Spacer()
                        
                        if let createdAt = currentMission.createdAt {
                            Text("Created \(createdAt, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Repository")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(currentMission.repoPath)
                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mac ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(currentMission.macId)
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Steps
                VStack(alignment: .leading, spacing: 16) {
                    Text("Steps")
                        .font(.headline)
                    
                    ForEach(currentMission.plan.plan) { step in
                        StepCardView(step: step)
                    }
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("Mission Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.refreshMission(currentMission)
                        if let updated = viewModel.missions.first(where: { $0.id == currentMission.id }) {
                            currentMission = updated
                        }
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onChange(of: viewModel.missions) { missions in
            if let updated = missions.first(where: { $0.id == currentMission.id }) {
                currentMission = updated
            }
        }
    }
    
    private func statusIcon(for status: MissionStatus) -> String {
        switch status {
        case .pending: return "clock"
        case .running: return "play.circle"
        case .done: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    private func statusColor(for status: MissionStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .running: return .blue
        case .done: return .green
        case .failed: return .red
        }
    }
}

struct StepCardView: View {
    let step: Step
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(step.title)
                    .font(.headline)
                
                Spacer()
                
                Label(step.status.rawValue.capitalized, systemImage: stepStatusIcon(for: step.status))
                    .font(.caption)
                    .foregroundColor(stepStatusColor(for: step.status))
            }
            
            if !step.actions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Actions:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(step.actions.indices, id: \.self) { index in
                        ActionRowView(action: step.actions[index])
                    }
                }
            }
            
            if let marker = step.expectMarker {
                HStack {
                    Image(systemName: "tag")
                    Text("Expects marker: \(marker)")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
            
            if let logs = step.logs {
                if let stdout = logs.stdout, !stdout.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Output:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(stdout)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                if let stderr = logs.stderr, !stderr.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Error:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(stderr)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(stepStatusColor(for: step.status), lineWidth: 2)
        )
    }
    
    private func stepStatusIcon(for status: StepStatus) -> String {
        switch status {
        case .pending: return "clock"
        case .running: return "play.circle"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .stalled: return "exclamationmark.triangle.fill"
        }
    }
    
    private func stepStatusColor(for status: StepStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        case .stalled: return .orange
        }
    }
}

struct ActionRowView: View {
    let action: Action
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: actionIcon(for: action.type))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(action.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let app = action.app {
                    Text("App: \(app)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if let path = action.path {
                    Text("Path: \(path)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if let cmd = action.cmd {
                    Text("Cmd: \(cmd)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if let prompt = action.prompt {
                    Text("Prompt: \(prompt)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func actionIcon(for type: ActionType) -> String {
        switch type {
        case .openApp: return "app.badge"
        case .screenshot: return "camera"
        case .runCommand: return "terminal"
        case .kiroPrompt: return "message"
        case .waitForMarker: return "tag"
        }
    }
}



