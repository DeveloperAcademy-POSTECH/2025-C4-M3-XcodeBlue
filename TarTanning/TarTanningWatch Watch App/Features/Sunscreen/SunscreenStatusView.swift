//
//  SunscreenStatusView.swift
//  TarTanning (watchOS Target)
//
//  Created by taeni on 7/18/25.
//

import SwiftUI

struct SunscreenStatusView: View {
    @StateObject private var viewModel = SunscreenViewModel.shared
    @State private var isStartingAnimation = false
    @State private var startProgress: Double = 0.0
    @State private var buttonScale: Double = 1.0
    @State private var buttonOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            Color(.suncreenBackground)
                .ignoresSafeArea()
            
            VStack(spacing: isStartingAnimation ? 0 : 27) {
                // 시작 애니메이션 중에는 상단 Spacer 추가로 중앙 배치
                if isStartingAnimation {
                    Spacer()
                }
                
                // 메인 아이콘 영역
                MainIconView(
                    isActive: viewModel.isActive,
                    isStarting: isStartingAnimation,
                    startProgress: startProgress
                )
                
                // 시작 애니메이션 중에는 하단 Spacer 추가로 중앙 배치
                if isStartingAnimation {
                    Spacer()
                } else {
                    // 컨트롤 버튼 영역
                    ControlButtonView(
                        isActive: viewModel.isActive,
                        isStarting: isStartingAnimation,
                        buttonScale: buttonScale,
                        buttonOpacity: buttonOpacity,
                        action: handleButtonTap
                    )
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isStartingAnimation)
        }
        .onAppear {
            WatchConnectivityManager.shared.activateSession()
        }
    }
    
    private func handleButtonTap() {
        if !viewModel.isActive {
            startSunscreenMode()
        } else {
            stopSunscreenMode()
        }
    }
    
    private func startSunscreenMode() {
        // 시작 애니메이션 시작
        isStartingAnimation = true
        
        // 버튼 축소 및 페이드아웃
        withAnimation(.easeInOut(duration: 0.5)) {
            buttonScale = 0.8
            buttonOpacity = 0.0
        }
        
        // 프로그레스 바 애니메이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 2.0)) {
                startProgress = 1.0
            }
        }
        
        // 타이머 시작 및 애니메이션 정리
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            viewModel.startSunscreenProtection(duration: 120 * 60)
            
            // 애니메이션 상태 정리
            isStartingAnimation = false
            startProgress = 0.0
            buttonScale = 1.0
            buttonOpacity = 1.0
        }
    }
    
    private func stopSunscreenMode() {
        viewModel.stopSunscreenProtection()
    }
}

// MARK: - MainIconView Component
struct MainIconView: View {
    let isActive: Bool
    let isStarting: Bool
    let startProgress: Double
    
    @State private var iconScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 메인 아이콘
            Image(systemName: "cloud.sun.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 88)
                .padding()
                .foregroundColor(.white)
                .scaleEffect(iconScale)
                .symbolEffect(.pulse, options: .repeating, isActive: isActive && !isStarting)
                .onChange(of: isStarting) { starting in
                    if starting {
                        // 시작 애니메이션: 크기 증가
                        withAnimation(.easeInOut(duration: 1.0)) {
                            iconScale = 1.36 // 88 * 1.36 ≈ 120
                        }
                        
                        // 1초 후 원래 크기로 복귀
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                iconScale = 1.0
                            }
                        }
                    } else {
                        // 애니메이션 종료 시 원래 크기로 즉시 복귀
                        withAnimation(.easeOut(duration: 0.3)) {
                            iconScale = 1.0
                        }
                    }
                }
            
            // 시작 시 프로그레스 애니메이션
            if isStarting {
                Circle()
                    .trim(from: 0.0, to: startProgress)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

struct ControlButtonView: View {
    let isActive: Bool
    let isStarting: Bool
    let buttonScale: Double
    let buttonOpacity: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label {
                Text(isActive ? "선크림 모드 끄기" : "선크림 모드")
                    .padding(.leading, 8)
            } icon: {
                Image(systemName: isActive ? "stop.circle" : "cloud.sun")
            }
            .font(.caption)
            .foregroundColor(Color.sunscreenButtonText)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 24)
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
        .scaleEffect(buttonScale)
        .opacity(buttonOpacity)
    }
}

#Preview("대기 상태") {
    SunscreenStatusView()
}

#if DEBUG
#Preview("진행 중 상태") {
    struct PreviewWrapper: View {
        @StateObject private var mockViewModel = MockSunscreenViewModel.active
        
        var body: some View {
            SunscreenStatusView()
                .environmentObject(mockViewModel)
        }
    }
    return PreviewWrapper()
}
#endif
