import SwiftUI
import Combine

struct DashboardTimerView: View {
    @Binding var isPresented: Bool
    
    @State private var remainingTime: TimeInterval = 0
    @State private var state: TimerState = .stopped
    @State private var cancellables = Set<AnyCancellable>()
    
    @StateObject private var timerManager = SunscreenViewModel.shared
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "cloud.sun")
                .font(.system(size: 32))
                .foregroundColor(.key00)
            
            // 남은 시간
            Text(timeDisplayString)
                .font(.system(size: 75, weight: .semibold))
                .foregroundColor(.key00)
                .animation(.easeInOut(duration: 0.3), value: timerManager.isActive)
                .padding(.bottom, 24)
            
            Text(timerStatusText)
                .fontWeight(.semibold)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button {
                isPresented = false
            } label: {
                Label("오늘 UV 노출량 보기", systemImage: "sun.max")
                    .background(Color.white02)
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                    )
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.linear01, Color.linear02]),
                startPoint: .top,
                endPoint: .center
            )
        )
        .cornerRadius(36)
        .onAppear {
            setupBindings()
        }
    }
}

extension DashboardTimerView {
    var timeDisplayString: String {
        if remainingTime <= 0 {
            return "00:00"
        }
        
        let hours = Int(remainingTime) / 3600
        let minutes = Int(remainingTime) % 3600 / 60
        
        if hours > 0 {
            return String(format: "%02d:%02d", hours, minutes)
        } else {
            return String(format: "00:%02d", minutes)
        }
    }
    
    var isRunning: Bool {
        return state == .running
    }
    
    var isPaused: Bool {
        return state == .paused
    }
    
    var isStopped: Bool {
        return state == .stopped
    }
    
    var timerStatusText: String {
        switch state {
        case .stopped:
            return "선크림 타이머를 \nWatch에서 작동시켜주세요"
        case .running:
            return "선크림 보호모드 작동 중"
        case .paused:
            return "타이머 보호모드 일시정지"
        }
    }
}

extension DashboardTimerView {
    func setupBindings() {
        timerManager.$remainingTime
            .receive(on: DispatchQueue.main)
            .assign(to: \.remainingTime, on: self)
            .store(in: &cancellables)
        
        timerManager.$timerState
            .receive(on: DispatchQueue.main)
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
    
    func startDefaultTimer() {
        timerManager.startSunscreenProtection(duration: 2 * 60 * 60)
    }
    
    func pauseTimer() {
        timerManager.pauseSunscreenProtection()
    }
    
    func resumeTimer() {
        timerManager.resumeSunscreenProtection()
    }
    
    func stopTimer() {
        timerManager.stopSunscreenProtection()
    }
}

#Preview {
    DashboardTimerView(isPresented: .constant(true))
}
