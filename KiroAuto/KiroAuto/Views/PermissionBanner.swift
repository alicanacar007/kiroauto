//
//  PermissionBanner.swift
//  KiroAuto
//
//  Created by Ali Can Acar on 12/5/25.
//

import SwiftUI

struct PermissionBanner: View {
    @ObservedObject var permissionService: PermissionService
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 24, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Accessibility Permission Required")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                Text("KiroAuto needs Accessibility access to control Kiro and automate tasks")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.orange.opacity(0.8))
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Button(action: {
                    permissionService.requestAccessibilityPermission()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Request")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: .orange.opacity(0.4), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    permissionService.openAccessibilitySettings()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "gear")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Settings")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.orange.opacity(0.4), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    _ = permissionService.checkAccessibilityPermission()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.orange)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .help("Recheck permissions")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .modifier(StitchedBorder(cornerRadius: 12, stitchCount: 4, borderColor: .orange))
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}
