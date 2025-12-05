//
//  BackendStatusView.swift
//  KiroAuto
//
//  Created by Ali Can Acar on 12/5/25.
//

import SwiftUI

struct BackendStatusView: View {
    @ObservedObject var backendService: BackendService
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 10) {
            // Status indicator with pulse animation
            ZStack {
                Circle()
                    .fill(backendService.isBackendOnline ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                    .shadow(color: (backendService.isBackendOnline ? Color.green : Color.red).opacity(0.5), radius: 4, x: 0, y: 0)
                
                if backendService.isBackendOnline {
                    Circle()
                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - pulseScale)
                        .onAppear {
                            withAnimation(
                                Animation.easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                            ) {
                                pulseScale = 2.0
                            }
                        }
                }
            }
            
            // Status text
            Text("Backend: \(backendService.backendStatusMessage)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(backendService.isBackendOnline ? .green : .red)
            
            // Refresh button
            Button(action: {
                Task {
                    await backendService.checkBackendStatus()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.kiroPrimary)
            }
            .buttonStyle(.plain)
            .help("Refresh backend status")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    backendService.isBackendOnline ?
                    LinearGradient(colors: [Color.green.opacity(0.15), Color.green.opacity(0.08)], startPoint: .top, endPoint: .bottom) :
                    LinearGradient(colors: [Color.red.opacity(0.15), Color.red.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    (backendService.isBackendOnline ? Color.green : Color.red).opacity(0.3),
                    lineWidth: 2
                )
        )
    }
}

