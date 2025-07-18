//
//  TimerNotificationManager.swift.swift
//  TarTanning
//
//  Created by taeni on 7/17/25.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class TimerViewModel: ObservableObject {
    
    @Published var remainingTime: TimeInterval = 0
    @Published var state: TimerState = .stopped
    @Published var selectedDuration: Double = 60
    
    private var cancellables = Set<AnyCancellable>()
    private let timerManager = TimerSyncManager.shared
    
    // MARK: - Computed Properties
    var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
    
    var progressPercentage: Double {
        guard selectedDuration > 0 else { return 0 }
        let elapsed = selectedDuration - remainingTime
        return max(0, min(1, elapsed / selectedDuration))
    }
    
    var stateDescription: String {
        switch state {
        case .stopped:
            return "정지됨"
        case .running:
            return "실행 중"
        case .paused:
            return "일시정지"
        }
    }
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        timerManager.$remainingTime
            .receive(on: DispatchQueue.main)
            .assign(to: \.remainingTime, on: self)
            .store(in: &cancellables)
        
        timerManager.$state
            .receive(on: DispatchQueue.main)
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
    
    func startTimer() {
        guard selectedDuration > 0 else { return }
        timerManager.start(duration: selectedDuration)
        
        // 알림 스케줄링
        let endTime = Date().addingTimeInterval(selectedDuration)
        TimerNotificationManager.shared.scheduleNotification(at: endTime)
    }
    
    func pauseTimer() {
        timerManager.pause()
        TimerNotificationManager.shared.cancelNotification()
    }
    
    func resumeTimer() {
        timerManager.resume()
        
        // 남은 시간으로 알림 재스케줄링
        if remainingTime > 0 {
            let endTime = Date().addingTimeInterval(remainingTime)
            TimerNotificationManager.shared.scheduleNotification(at: endTime)
        }
    }
    
    func stopTimer() {
        timerManager.stop()
        TimerNotificationManager.shared.cancelNotification()
    }
    
    func setDuration(_ duration: Double) {
        selectedDuration = max(1, duration)
    }
    
    func getPresetDurations() -> [Double] {
        return Array(stride(from: 20, through: 100, by: 5))
    }
}
