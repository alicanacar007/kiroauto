//
//  MissionListView.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import SwiftUI

struct MissionListView: View {
    @ObservedObject var viewModel: MissionViewModel
    @State private var showingCreateMission = false
    @State private var showingSettings = false
    var onLogout: (() -> Void)?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.missions.isEmpty {
                    ProgressView("Loading missions...")
                } else if viewModel.missions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No missions yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Create your first mission to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Create Mission") {
                            showingCreateMission = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(viewModel.missions) { mission in
                            NavigationLink {
                                MissionDetailView(mission: mission, viewModel: viewModel)
                            } label: {
                                MissionRowView(mission: mission)
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.deleteMission(viewModel.missions[index])
                                }
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.loadMissions()
                    }
                }
            }
            .navigationTitle("Missions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateMission = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateMission) {
                CreateMissionView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(onLogout: onLogout)
                    .onDisappear {
                        // Refresh if settings changed
                        Task {
                            await viewModel.loadMissions()
                        }
                    }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .task {
            await viewModel.loadMissions()
        }
    }
}

struct MissionRowView: View {
    let mission: Mission
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mission.prompt)
                .font(.headline)
                .lineLimit(2)
            
            HStack {
                Label(mission.status.rawValue.capitalized, systemImage: statusIcon(for: mission.status))
                    .font(.caption)
                    .foregroundColor(statusColor(for: mission.status))
                
                Spacer()
                
                if let createdAt = mission.createdAt {
                    Text(createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(mission.repoPath)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
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

