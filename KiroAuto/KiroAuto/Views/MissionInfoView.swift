//
//  MissionInfoView.swift
//  KiroAuto
//
//  Created by Ali Can Acar on 12/5/25.
//

import SwiftUI

struct MissionInfoView: View {
    let mission: Mission
    let currentStep: Step?
    let isRunning: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    let onNewMission: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left side - Mission Status
            missionStatusView
            
            // Right side - AI Generated Plan
            planView
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var missionStatusView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 10) {
                        BoltDecoration(size: 22, color: .frankensteinBolt)
                            .pulsing(duration: 2.5)
                        Text("Active Mission")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.frankensteinDarkGreen)
                    }
                    Spacer()
                    statusBadge
                }
                
                Divider()
                    .background(Color.frankensteinGreen.opacity(0.3))
                
                HStack(spacing: 24) {
                    missionIdView
                    
                    Rectangle()
                        .fill(Color.frankensteinGreen.opacity(0.3))
                        .frame(width: 2, height: 40)
                    
                    totalStepsView
                }
                
                if let currentStep = currentStep {
                    currentStepView(step: currentStep)
                }
            }
            
            actionButtons
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.frankensteinGreen.opacity(0.1), Color.frankensteinLightGreen.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .modifier(StitchedBorder(cornerRadius: 16, stitchCount: 5, borderColor: .frankensteinGreen))
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            if mission.status == "running" {
                BoltDecoration(size: 14, color: .frankensteinBolt)
                    .pulsing(duration: 1.5)
            }
            Text(mission.status.capitalized)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(
                            mission.status == "running" ?
                            LinearGradient(colors: [Color.green.opacity(0.3), Color.green.opacity(0.15)], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                        )
                )
                .foregroundColor(mission.status == "running" ? .green : .orange)
                .shadow(color: (mission.status == "running" ? Color.green : Color.orange).opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
    private var missionIdView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mission ID")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.frankensteinDarkGreen.opacity(0.7))
            Text(mission.id)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.frankensteinDarkGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.8))
                )
        }
    }
    
    private var totalStepsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Total Steps")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.frankensteinDarkGreen.opacity(0.7))
            HStack(spacing: 6) {
                Text("\(mission.plan.plan.count)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.frankensteinGreen)
                BoltDecoration(size: 18, color: .frankensteinBolt)
            }
        }
    }
    
    private func currentStepView(step: Step) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Current Step")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.frankensteinDarkGreen.opacity(0.7))
            HStack(spacing: 8) {
                BoltDecoration(size: 16, color: .frankensteinBolt)
                    .pulsing(duration: 2.0)
                Text(step.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.frankensteinGreen)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.frankensteinLightGreen.opacity(0.2))
            )
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 14) {
            if !isRunning {
                Button(action: onStart) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Start Mission")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .frankensteinButton()
            } else {
                Button(action: onStop) {
                    HStack(spacing: 10) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Stop Mission")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .red.opacity(0.4), radius: 6, x: 0, y: 3)
                    )
                }
            }
            
            Button(action: onNewMission) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("New Mission")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.frankensteinDarkGreen)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.frankensteinGreen.opacity(0.4), lineWidth: 2)
                )
            }
        }
    }
    
    private var planView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.purple)
                Text("AI Generated Plan")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                Spacer()
            }
            
            Divider()
                .background(Color.purple.opacity(0.3))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(mission.plan.plan.enumerated()), id: \.offset) { index, step in
                        planStepRow(index: index, step: step)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.08), Color.purple.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .modifier(StitchedBorder(cornerRadius: 16, stitchCount: 5, borderColor: .purple))
    }
    
    private func planStepRow(index: Int, step: Step) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number badge with bolt decoration
            ZStack {
                Circle()
                    .fill(
                        currentStep?.stepId == step.stepId ?
                        LinearGradient(colors: [Color.purple, Color.purple.opacity(0.7)], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 32, height: 32)
                    .shadow(color: (currentStep?.stepId == step.stepId ? Color.purple : Color.gray).opacity(0.3), radius: 4, x: 0, y: 2)
                
                if currentStep?.stepId == step.stepId {
                    BoltDecoration(size: 18, color: .frankensteinBolt)
                        .pulsing(duration: 2.0)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .font(.system(size: 14, weight: currentStep?.stepId == step.stepId ? .bold : .semibold, design: .rounded))
                    .foregroundColor(currentStep?.stepId == step.stepId ? .purple : .primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.frankensteinBolt.opacity(0.7))
                    Text("\(step.actions.count) actions")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    currentStep?.stepId == step.stepId ?
                    LinearGradient(colors: [Color.purple.opacity(0.15), Color.purple.opacity(0.05)], startPoint: .leading, endPoint: .trailing) :
                    LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    currentStep?.stepId == step.stepId ? Color.purple.opacity(0.4) : Color.clear,
                    lineWidth: 2
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep?.stepId == step.stepId)
    }
}

