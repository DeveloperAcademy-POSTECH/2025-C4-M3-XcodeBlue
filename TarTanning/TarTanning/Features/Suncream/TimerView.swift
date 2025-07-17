//
//  TimerNotificationManager.swift.swift
//  TarTanning
//
//  Created by taeni on 7/17/25.
//

import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @StateObject private var timerManager = TimerSyncManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // 연결 상태 표시
            HStack {
                Circle()
                    .fill(timerManager.connectionStatus == "연결됨" ? .green : .orange)
                    .frame(width: 8, height: 8)
                Text("\(timerManager.connectionStatus)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("🍎 iPhone")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 헤더
            Text("타이머")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // 남은 시간 표시
            VStack(spacing: 8) {
                Text("남은 시간")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(viewModel.formattedRemainingTime)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(timerManager.state == .running ? .blue : .primary)
                    .animation(.easeInOut(duration: 0.3), value: timerManager.state)
            }
            
            // 진행률 바
            if !viewModel.isStopped {
                ProgressView(value: viewModel.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: timerManager.state == .running ? .blue : .orange))
                    .scaleEffect(y: 2)
                    .animation(.easeInOut, value: viewModel.progressPercentage)
            }
            
            // 시간 선택 (정지 상태일 때만)
            if viewModel.isStopped {
                VStack(spacing: 12) {
                    Text("시간 선택")
                        .font(.headline)
                    
                    Picker("시간 선택", selection: $viewModel.selectedDuration) {
                        ForEach(viewModel.getPresetDurations(), id: \.self) { value in
                            Text("\(Int(value))초").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
            }
            
            // 컨트롤 버튼
            HStack(spacing: 20) {
                if viewModel.isStopped {
                    Button("시작") {
                        viewModel.startTimer()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else if viewModel.isRunning {
                    Button("일시정지") {
                        viewModel.pauseTimer()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("중지") {
                        viewModel.stopTimer()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                } else if viewModel.isPaused {
                    Button("재개") {
                        viewModel.resumeTimer()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("중지") {
                        viewModel.stopTimer()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
            }
            
            // 상태 표시
            VStack(spacing: 4) {
                Text("상태: \(viewModel.stateDescription)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if timerManager.connectionStatus != "연결됨" {
                    Text("⚠️ Watch와 독립적으로 동작 중")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding(.top)
        }
        .padding()
        .navigationTitle("타이머")
    }
}

#Preview {
    TimerView()
}
