//
//  ContentView.swift
//  KiroAuto
//
//  Created by Ali Can Acar on 12/5/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel = MissionViewModel()
    @StateObject private var permissionService = PermissionService()
    @StateObject private var backendService = BackendService()
    @State private var user = "ali"
    @State private var prompt = ""
    @State private var repoPath = ""
    @State private var autoStart = false
    @State private var showCopiedAlert = false
    @State private var showSiriCircle = false
    
    func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = "Select Repository"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                repoPath = url.path
            }
        }
    }
    
    func copyLogsToClipboard() {
        let logsText = viewModel.logs.joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(logsText, forType: .string)
        
        showCopiedAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedAlert = false
        }
    }
    
    func createMissionAction() {
        Task {
            await viewModel.createMission(user: user, prompt: prompt, repoPath: repoPath)
            if autoStart {
                viewModel.startMission()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Logo header with AWS and Kiro logos
            LogoHeaderView()
            
            HStack(spacing: 20) {
                // Frankenstein character on the left
                FloatingFrankenstein(size: 100)
                    .padding(.leading, 20)
                
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // Frankenstein bolt decoration
                        BoltDecoration(size: 32, color: .frankensteinBolt)
                            .pulsing(duration: 3.0)
                        
                        Text("Kiro Auto Controller")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.frankensteinDarkGreen)
                        
                        BoltDecoration(size: 32, color: .frankensteinBolt)
                            .pulsing(duration: 3.0)
                        
                        // Siri button - more visible
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSiriCircle.toggle()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.frankensteinGreen, .frankensteinDarkGreen],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .frankensteinDarkGreen.opacity(0.4), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Show Siri Circle")
                        .padding(.leading, 8)
                    }
                    
                    Text("Autonomous Development Assistant")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.frankensteinDarkGreen.opacity(0.8))
                }
                
                // Frankenstein character on the right
                FloatingFrankenstein(size: 100)
                    .padding(.trailing, 20)
            }
            
            // Backend status indicator
            BackendStatusView(backendService: backendService)
        }
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Frankenstein-themed background
                Color.frankensteinBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    permissionBanner
                    headerView
                    missionFormSection
                    missionInfoSection
                    logsSection
                }
                
                // Floating Siri button in top-right corner
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSiriCircle.toggle()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.frankensteinGreen, .frankensteinDarkGreen],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .frankensteinDarkGreen.opacity(0.5), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Show Siri Circle")
                        .padding(.top, 16)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
                
                // Siri Circle Overlay
                if showSiriCircle {
                    SiriCircleView()
                        .zIndex(1000)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSiriCircle = false
                            }
                        }
                }
            }
            .frame(minWidth: 900, minHeight: 750)
        }
        .onAppear {
            // Check permission status
            _ = permissionService.checkAccessibilityPermission()
            
            // If permission is not granted, request it (this will prompt and add app to list)
            if !permissionService.hasAccessibilityPermission {
                // Small delay to ensure UI is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    permissionService.requestAccessibilityPermission()
                }
            }
        }
    }
    
    @ViewBuilder
    private var permissionBanner: some View {
        if !permissionService.hasAccessibilityPermission {
            PermissionBanner(permissionService: permissionService)
        }
    }
    
    @ViewBuilder
    private var missionFormSection: some View {
        if viewModel.currentMission == nil {
            MissionFormView(
                user: $user,
                prompt: $prompt,
                repoPath: $repoPath,
                autoStart: $autoStart,
                onSelectDirectory: selectDirectory,
                onCreateMission: createMissionAction
            )
        }
    }
    
    @ViewBuilder
    private var missionInfoSection: some View {
        if let mission = viewModel.currentMission {
            MissionInfoView(
                mission: mission,
                currentStep: viewModel.currentStep,
                isRunning: viewModel.isRunning,
                onStart: { viewModel.startMission() },
                onStop: { viewModel.stopMission() },
                onNewMission: {
                    viewModel.currentMission = nil
                    viewModel.logs = []
                }
            )
        }
    }
    
    private var logsSection: some View {
        LogsView(
            logs: viewModel.logs,
            showCopiedAlert: $showCopiedAlert,
            onCopy: copyLogsToClipboard
        )
    }
}

#Preview {
    ContentView()
}
