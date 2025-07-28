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
            Image(systemName: "cloud.sun")
                .font(.system(size: 32))
                .foregroundColor(.key00)
                .padding(.top, 96)
            
            // 남은 시간
            Text(timeDisplayString)
                .font(.system(size: 75, weight: .semibold))
                .foregroundColor(.key00)
                .animation(.easeInOut(duration: 0.3), value: timerManager.isActive)
            
            Text(timerStatusText)
                .font(.system(size: 17))
                .bold()
                .padding(.bottom, 20)
            
            Button {
                isPresented = false
            } label: {
                Text("MED 수치 보기")
                    .font(.system(size: 15))
                    .bold()
                    .frame(width: 130, height: 35)
                    .background(Color.white)
                    .cornerRadius(20)
            }
            .padding(.horizontal, 104)
            .padding(.bottom, 118)
        }
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.15))
        .cornerRadius(20)
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
            return "선크림 타이머"
        case .running:
            return "선크림 보호 중"
        case .paused:
            return "타이머 일시정지"
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
