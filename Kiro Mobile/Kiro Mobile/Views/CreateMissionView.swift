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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Mission Details")) {
                    TextField("What do you want to build?", text: $prompt, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("Repository Path", text: $repoPath)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(footer: Text("The mission will be sent to your Mac client for execution.")) {
                    Button {
                        Task {
                            isCreating = true
                            let success = await viewModel.createMission(
                                prompt: prompt,
                                repoPath: repoPath
                            )
                            if success {
                                dismiss()
                            }
                            isCreating = false
                        }
                    } label: {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Mission")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(prompt.isEmpty || repoPath.isEmpty || isCreating)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("New Mission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}


