import SwiftUI

struct WatchSunscreenTimerView: View {
    @StateObject private var viewModel = SunscreenViewModel.shared
    @State private var showCompletionAnimation = false
    @State private var showResetButton = false

    // 부모에서 currentTab을 바인딩으로 전달받음
    @Binding var currentTab: Int

    var body: some View {
        ZStack {
            Color(.suncreenBackground)
                .ignoresSafeArea()

            // 좌측 상단 X 버튼
            VStack {
                HStack {
                    Button(action: {
                        viewModel.resetTimer()
                        currentTab = 0
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold)) // 원하는 크기로 조정
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.2))
                                    .frame(width: 28, height: 28)
                                    // 아이콘보다 약간만 크게
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                Spacer()
            }
            .padding(.bottom, 24)
            .padding(.leading, 16)

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
                        Text("선크림이 보호하고 있어요")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.suncreenExplainText)
                            .multilineTextAlignment(.center)
                    } else if viewModel.timerState == .stopped && viewModel.isCompleted {
                        Text("선크림 보호가 종료됩니다")
                            .font(.caption)
                            .foregroundColor(.suncreenExplainText)
                            .multilineTextAlignment(.center)
                    } else {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showCompletionAnimation = false
            }
        }
    }
}

// 기존 TimerState enum 사용 (stopped, running, paused)

// 프리뷰 예시 (currentTab을 .constant로 전달)
#Preview {
    WatchSunscreenTimerView(currentTab: .constant(1))
}
