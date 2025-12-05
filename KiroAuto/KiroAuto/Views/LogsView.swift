//
//  LogsView.swift
//  KiroAuto
//
//  Created by Ali Can Acar on 12/5/25.
//

import SwiftUI

struct LogsView: View {
    let logs: [String]
    @Binding var showCopiedAlert: Bool
    let onCopy: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            logsHeader
            
            logsContent
        }
    }
    
    private var logsHeader: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.frankensteinGreen)
                Text("Execution Logs")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.frankensteinDarkGreen)
            }
            Spacer()
            
            if showCopiedAlert {
                copiedAlertView
            }
            
            if !logs.isEmpty {
                logsCountView
                copyButton
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var copiedAlertView: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 14, weight: .bold))
            Text("Copied!")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.15))
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    private var logsCountView: some View {
        HStack(spacing: 4) {
            BoltDecoration(size: 12, color: .frankensteinBolt)
            Text("\(logs.count) entries")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.frankensteinDarkGreen)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.frankensteinGreen.opacity(0.1))
        )
    }
    
    private var copyButton: some View {
        Button(action: onCopy) {
            Image(systemName: "doc.on.doc.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
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
        .help("Copy all logs to clipboard")
    }
    
    private var logsContent: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 6) {
                    if logs.isEmpty {
                        emptyStateView
                    } else {
                        logsList
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .onChange(of: logs.count) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
        }
        .frame(minHeight: 350, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .modifier(StitchedBorder(cornerRadius: 16, stitchCount: 6, borderColor: .frankensteinDarkGreen))
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.frankensteinGreen.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "text.alignleft")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.frankensteinGreen.opacity(0.6))
            }
            VStack(spacing: 8) {
                Text("No logs yet")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.frankensteinDarkGreen)
                Text("Logs will appear here when you start a mission")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.frankensteinDarkGreen.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
    
    private var logsList: some View {
        ForEach(Array(logs.enumerated()), id: \.offset) { index, log in
            logRow(index: index, log: log)
                .id(index)
        }
    }
    
    private func logRow(index: Int, log: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        index % 2 == 0 ?
                        Color.frankensteinGreen.opacity(0.15) :
                        Color.frankensteinLightGreen.opacity(0.1)
                    )
                    .frame(width: 28, height: 28)
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.frankensteinDarkGreen)
            }
            
            Text(log)
                .font(.system(size: 13, design: .monospaced))
                .textSelection(.enabled)
                .foregroundColor(.frankensteinDarkGreen.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    index % 2 == 0 ?
                    Color.clear :
                    Color.frankensteinGreen.opacity(0.05)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: index)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastIndex = logs.indices.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastIndex, anchor: .bottom)
            }
        }
    }
}

