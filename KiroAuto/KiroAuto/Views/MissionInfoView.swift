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
                    SectionHeader("Active Mission", icon: "rocket.fill")
                    Spacer()
                    statusBadge
                }
                
                Divider()
                    .background(Color.kiroPrimary.opacity(0.2))
                
                HStack(spacing: 24) {
                    missionIdView
                    
                    Rectangle()
                        .fill(Color.kiroPrimary.opacity(0.2))
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
        .modernCard()
    }
    
    private var statusBadge: some View {
        StatusBadge(
            text: mission.status,
            status: mission.status == "running" ? .running : (mission.status == "done" ? .success : .warning)
        )
    }
    
    private var missionIdView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mission ID")
                .font(.system(size: 11, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
            Text(mission.id)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.kiroPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.kiroSurface)
                )
        }
    }
    
    private var totalStepsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Total Steps")
                .font(.system(size: 11, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
            HStack(spacing: 6) {
                Text("\(mission.plan.plan.count)")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundColor(.kiroPrimary)
                Image(systemName: "list.number")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.kiroAccent)
            }
        }
    }
    
    private func currentStepView(step: Step) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Current Step")
                .font(.system(size: 11, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.kiroPrimary)
                    .pulsing(duration: 2.0)
                Text(step.title)
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(.kiroPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.kiroPrimary.opacity(0.1))
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
                            .font(.system(size: 15, weight: .semibold, design: .default))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .modernButton(variant: .primary, size: .medium)
            } else {
                Button(action: onStop) {
                    HStack(spacing: 10) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Stop Mission")
                            .font(.system(size: 15, weight: .semibold, design: .default))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .modernButton(variant: .danger, size: .medium)
            }
            
            Button(action: onNewMission) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("New Mission")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                }
                .foregroundColor(.kiroPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.kiroCard)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.kiroPrimary.opacity(0.3), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var planView: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader("AI Generated Plan", icon: "sparkles", color: .purple)
            
            Divider()
                .background(Color.purple.opacity(0.2))
            
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
        .modernCard()
    }
    
    private func planStepRow(index: Int, step: Step) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number badge
            ZStack {
                Circle()
                    .fill(
                        currentStep?.stepId == step.stepId ?
                        LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 32, height: 32)
                    .shadow(color: (currentStep?.stepId == step.stepId ? Color.purple : Color.gray).opacity(0.3), radius: 4, x: 0, y: 2)
                
                if currentStep?.stepId == step.stepId {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .pulsing(duration: 2.0)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .bold, design: .default))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .font(.system(size: 14, weight: currentStep?.stepId == step.stepId ? .bold : .semibold, design: .default))
                    .foregroundColor(currentStep?.stepId == step.stepId ? .purple : .primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.kiroAccent.opacity(0.7))
                    Text("\(step.actions.count) actions")
                        .font(.system(size: 11, weight: .medium, design: .default))
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
