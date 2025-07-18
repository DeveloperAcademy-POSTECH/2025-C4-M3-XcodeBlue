//
//  TimerNotificationManager.swift.swift
//  TarTanning
//
//  Created by taeni on 7/17/25.
//

import SwiftUI

struct WatchTimerView: View {
    @StateObject private var timerManager = TimerSyncManager.shared
    @State private var selectedDuration: Double = 30
    
    private let presetDurations: [Double] = [15, 30, 45, 60, 90, 120]
    
    var body: some View {
        TabView {
            // 타이머 화면
            timerDisplayView
            
            // 시간 선택 화면
            if timerManager.state == .stopped {
                durationSelectionView
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .onAppear {
            Task {
                await WatchTimerNotificationManager.shared.requestNotificationPermission()
            }
        }
    }
    
    private var timerDisplayView: some View {
        VStack(spacing: 8) {
            // 연결 상태
            HStack {
                Circle()
                    .fill(timerManager.connectionStatus == "연결됨" ? .green : .orange)
                    .frame(width: 6, height: 6)
                Text(timerManager.connectionStatus == "연결됨" ? "📱" : "🔄")
                    .font(.caption2)
                Spacer()
                Text("⌚️ Watch")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(formattedTime)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(timerManager.state == .running ? .blue : .primary)
                .minimumScaleFactor(0.5)
                .animation(.easeInOut(duration: 0.3), value: timerManager.state)
            
            // 진행률 링
            if timerManager.state != .stopped {
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(
                        timerManager.state == .running ? Color.blue : Color.orange,
                        lineWidth: 3
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 50, height: 50)
                    .animation(.easeInOut, value: progressPercentage)
            }
            
            // 컨트롤 버튼
            controlButtons
            
            VStack(spacing: 2) {
                Text(stateText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if timerManager.connectionStatus != "연결됨" {
                    Text("독립 동작")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var durationSelectionView: some View {
        VStack(spacing: 6) {
            Text("시간 선택")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
                ForEach(presetDurations, id: \.self) { duration in
                    Button("\(Int(duration))초") {
                        selectedDuration = duration
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(selectedDuration == duration ? .blue : .primary)
                    .font(.caption2)
                    .controlSize(.mini)
                }
            }
            
            Button("시작") {
                timerManager.start(duration: selectedDuration)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedDuration <= 0)
            .controlSize(.small)
        }
        .padding(.horizontal, 8)
    }
    
    private var controlButtons: some View {
        Group {
            if timerManager.state == .stopped {
                HStack(spacing: 8) {
                    Button("시작") {
                        timerManager.start(duration: selectedDuration)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
            } else if timerManager.state == .running {
                HStack(spacing: 8) {
                    Button("⏸") {
                        timerManager.pause()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    
                    Button("⏹") {
                        timerManager.stop()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                    .controlSize(.mini)
                }
            } else if timerManager.state == .paused {
                HStack(spacing: 8) {
                    Button("▶️") {
                        timerManager.resume()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                    
                    Button("⏹") {
                        timerManager.stop()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                    .controlSize(.mini)
                }
            } else {
                // 빈 상태를 위한 기본 뷰
                HStack(spacing: 8) {
                    EmptyView()
                }
            }
        }
    }
    
    private var formattedTime: String {
        let minutes = Int(timerManager.remainingTime) / 60
        let seconds = Int(timerManager.remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var progressPercentage: CGFloat {
        guard selectedDuration > 0 else { return 0 }
        let elapsed = selectedDuration - timerManager.remainingTime
        return CGFloat(max(0, min(1, elapsed / selectedDuration)))
    }
    
    private var stateText: String {
        switch timerManager.state {
        case .stopped: return "정지됨"
        case .running: return "실행 중"
        case .paused: return "일시정지"
        }
    }
}

#Preview {
    WatchTimerView()
}
