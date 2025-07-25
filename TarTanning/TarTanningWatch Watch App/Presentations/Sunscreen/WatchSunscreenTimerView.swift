//
//  WatchSunscreenTimerView.swift
//  TarTanningWatch Watch App
//
//  Created by taeni on 7/19/25.
//

import SwiftUI

struct WatchSunscreenTimerView: View {
    @StateObject private var viewModel = SunscreenViewModel.shared
    @State private var showCompletionAnimation = false
    @State private var showResetButton = false
    
    var body: some View {
        ZStack {
            Color(.suncreenBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 7) {
                // 진행률 표시 원형 프로그레스
                VStack {
                    ZStack {
                        CircleProgressView(
                            remainingTime: viewModel.remainingTime,
                            totalDuration: viewModel.totalDuration
                        )
                        
                        // 완료 애니메이션
                        if showCompletionAnimation {
                            Circle()
                                .stroke(Color.green, lineWidth: 3)
                                .opacity(0.8)
                                .scaleEffect(1.2)
                                .animation(.easeOut(duration: 1.0), value: showCompletionAnimation)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // 상태 메시지
                VStack(spacing: 4) {
                    if viewModel.timerState == .running {
                        // 사용 중
                        Text("선크림이 보호하고 있어요")
                            .font(.caption)
                            .foregroundColor(.suncreenExplainText)
                            .multilineTextAlignment(.center)
                        
                    } else if viewModel.timerState == .stopped && viewModel.isCompleted {
                        // 사용 완료 시
                        Text("선크림 보호가 종료됩니다")
                            .font(.caption)
                            .foregroundColor(.suncreenExplainText)
                            .multilineTextAlignment(.center)
                        
                    } else {
                        // 사용 전 / 완료 후 리셋됨
                        Text("선크림을 바른 후 시작 버튼을 눌러주세요")
                            .font(.caption)
                            .foregroundColor(.suncreenExplainText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, 15)
                
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            WatchConnectivityManager.shared.activateSession()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sunscreenTimerCompleted)) { _ in
            handleTimerCompletion()
        }
        .onChange(of: viewModel.isCompleted) { _, isCompleted in
            if isCompleted {
                // 완료 후 3초 뒤에 리셋 버튼 표시
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showResetButton = true
                    }
                }
                
                // 완료 후 30초 뒤에 자동으로 ready 상태로 전환
                DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                    if viewModel.isCompleted && !viewModel.isActive {
                        resetTimer()
                    }
                }
            }
        }
    }
    
    private func toggleTimer() {
        if viewModel.isActive {
            viewModel.stopSunscreenProtection()
        } else {
            // 2시간 선크림 보호 시작
            viewModel.startSunscreenProtection(duration: 120 * 60)
        }
    }
    
    private func resetTimer() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            viewModel.resetTimer()
            showCompletionAnimation = false
            showResetButton = false
        }
    }
    
    private func handleTimerCompletion() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showCompletionAnimation = true
        }
        
        // 완료 애니메이션 자동 해제
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showCompletionAnimation = false
            }
        }
    }
}

// 기존 TimerState enum 사용 (stopped, running, paused)

#Preview {
    WatchSunscreenTimerView()
}
