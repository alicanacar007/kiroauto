//
//  MissionFormView.swift
//  KiroAuto
//
//  Created by Ali Can Acar on 12/5/25.
//

import SwiftUI

struct MissionFormView: View {
    @Binding var user: String
    @Binding var prompt: String
    @Binding var repoPath: String
    @Binding var autoStart: Bool
    let onSelectDirectory: () -> Void
    let onCreateMission: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                BoltDecoration(size: 24, color: .frankensteinBolt)
                Text("Create New Mission")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.frankensteinDarkGreen)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("User")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.frankensteinDarkGreen)
                    }
                    TextField("Enter username", text: $user)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.frankensteinGreen.opacity(0.3), lineWidth: 2)
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task Description")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.frankensteinDarkGreen)
                    TextField("e.g., 'Build a React calculator'", text: $prompt)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.frankensteinGreen.opacity(0.3), lineWidth: 2)
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Repository Path")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.frankensteinDarkGreen)
                    HStack(spacing: 10) {
                        TextField("Select or enter path", text: $repoPath)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.frankensteinGreen.opacity(0.3), lineWidth: 2)
                            )
                        
                        Button(action: onSelectDirectory) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [.frankensteinGreen, .frankensteinDarkGreen],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                )
                                .shadow(color: .frankensteinDarkGreen.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .help("Select repository folder")
                    }
                }
                
                HStack(spacing: 10) {
                    Toggle(isOn: $autoStart) {
                        HStack(spacing: 8) {
                            BoltDecoration(size: 18, color: .frankensteinBolt)
                            Text("Auto-start mission after creation")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.frankensteinDarkGreen)
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(.frankensteinGreen)
                }
            }
            
            Button(action: onCreateMission) {
                HStack(spacing: 10) {
                    BoltDecoration(size: 20, color: .frankensteinBolt)
                    Text("Create Mission")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .frankensteinButton()
            .disabled(prompt.isEmpty || repoPath.isEmpty)
            .opacity(prompt.isEmpty || repoPath.isEmpty ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: prompt.isEmpty || repoPath.isEmpty)
        }
        .padding(24)
        .frankensteinCard()
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
