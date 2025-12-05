//
//  CreateMissionView.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import SwiftUI

struct CreateMissionView: View {
    @ObservedObject var viewModel: MissionViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var prompt: String = ""
    @State private var repoPath: String = ""
    @State private var isCreating = false
    @State private var showUsernameError = false
    @State private var showRepoPathField = false
    
    // Example missions
    private let exampleMissions = [
        ExampleMission(
            title: "To-do list app",
            description: "Build a to-do list app with local storage.",
            gradientColors: [Color(red: 0.2, green: 0.4, blue: 0.9), Color(red: 0.3, green: 0.5, blue: 1.0)]
        ),
        ExampleMission(
            title: "Custom login screen",
            description: "A SwiftUI login screen with social login buttons.",
            gradientColors: [Color(red: 1.0, green: 0.5, blue: 0.2), Color(red: 1.0, green: 0.6, blue: 0.3)]
        ),
        ExampleMission(
            title: "Weather dashboard",
            description: "Create a beautiful weather app with location services.",
            gradientColors: [Color(red: 0.4, green: 0.7, blue: 0.9), Color(red: 0.5, green: 0.8, blue: 1.0)]
        ),
        ExampleMission(
            title: "Note-taking app",
            description: "Build a markdown-enabled note-taking application.",
            gradientColors: [Color(red: 0.6, green: 0.4, blue: 0.9), Color(red: 0.7, green: 0.5, blue: 1.0)]
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Large question
                        Text("What should Kiro build?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        // Text input field
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .frame(minHeight: 120)
                                
                                if prompt.isEmpty {
                                    Text("Describe your project, app, or feature...")
                                        .foregroundColor(Color(UIColor.placeholderText))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 24)
                                        .allowsHitTesting(false)
                                }
                                
                                TextEditor(text: $prompt)
                                    .frame(minHeight: 120)
                                    .padding(12)
                                    .background(Color.clear)
                                    .scrollContentBackground(.hidden)
                            }
                            
                            // Tip text
                            Text("Tip: Be as specific as possible for the best results.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, 20)
                        
                        // Repository path field (collapsible)
                        if showRepoPathField {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Repository Path")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("Repository Path", text: $repoPath)
                                    .textFieldStyle(.plain)
                                    .padding(16)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(12)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Error message
                        if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Example missions section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Or try an example")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(exampleMissions) { example in
                                        ExampleMissionCard(example: example) {
                                            prompt = example.description
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Generate Mission button
                        Button {
                            Task {
                                isCreating = true
                                viewModel.errorMessage = nil
                                let success = await viewModel.createMission(
                                    prompt: prompt,
                                    repoPath: repoPath.isEmpty ? "/tmp/kiro-project" : repoPath
                                )
                                if success {
                                    dismiss()
                                } else {
                                    // Show error if username is missing
                                    if let error = viewModel.errorMessage,
                                       error.contains("username") {
                                        showUsernameError = true
                                    }
                                }
                                isCreating = false
                            }
                        } label: {
                            HStack {
                                if isCreating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Generate Mission")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                prompt.isEmpty ? Color.gray.opacity(0.3) : Color(red: 0.5, green: 0.3, blue: 0.7)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .disabled(prompt.isEmpty || isCreating)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("New Mission")
                        .font(.headline)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showRepoPathField.toggle()
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert("Username Required", isPresented: $showUsernameError) {
                Button("Go to Settings") {
                    dismiss()
                    // Note: In a real app, you might want to navigate to settings here
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please set your username in Settings before creating a mission.")
            }
        }
    }
}

// Example Mission Model
struct ExampleMission: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let gradientColors: [Color]
}

// Example Mission Card View
struct ExampleMissionCard: View {
    let example: ExampleMission
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(example.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(example.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            .frame(width: 200, height: 120)
            .padding(16)
            .background(
                LinearGradient(
                    colors: example.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                // Abstract shapes decoration
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .offset(x: 120, y: -40)
                    
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .offset(x: 140, y: 20)
                }
            )
        }
        .buttonStyle(.plain)
    }
}


