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
            SectionHeader("Create New Mission", icon: "plus.circle.fill")
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("User")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(.kiroPrimary)
                    
                    TextField("Enter username", text: $user)
                        .textFieldStyle(ModernTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task Description")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(.kiroPrimary)
                    
                    TextField("e.g., 'Build a React calculator'", text: $prompt, axis: .vertical)
                        .textFieldStyle(ModernTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Repository Path")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(.kiroPrimary)
                    
                    HStack(spacing: 10) {
                        TextField("Select or enter path", text: $repoPath)
                            .textFieldStyle(ModernTextFieldStyle())
                        
                        Button(action: onSelectDirectory) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [.kiroPrimary, .kiroPrimaryDark],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: .kiroPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .help("Select repository folder")
                    }
                }
                
                HStack(spacing: 10) {
                    Toggle(isOn: $autoStart) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.kiroPrimary)
                            Text("Auto-start mission after creation")
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.kiroPrimary)
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(.kiroPrimary)
                }
            }
            
            Button(action: onCreateMission) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Create Mission")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .modernButton(variant: .primary, size: .medium)
            .disabled(prompt.isEmpty || repoPath.isEmpty)
            .opacity(prompt.isEmpty || repoPath.isEmpty ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: prompt.isEmpty || repoPath.isEmpty)
        }
        .modernCard()
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
