//
//  SunscreenViewModel+TimerControl.swift
//  TarTanning
//
//  Created by taeni on 7/28/25.
//

import Foundation
import Combine

#if os(watchOS)
import WatchKit
#endif

// MARK: - Timer Control & Observers
extension SunscreenViewModel {
    
    /// 타이머 상태 관찰자 설정
    internal func setupTimerObservers() {
        // TimerSyncManager의 상태를 관찰
        timerManager.$remainingTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                guard let self = self, !self.isUpdatingFromRemote else { return }
                self.remainingTime = time
                self.sendSunscreenStateToCounterpart()
            }
            .store(in: &cancellables)
        
        timerManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self, !self.isUpdatingFromRemote else { return }
                self.timerState = state
                self.isActive = (state == .running)
                
                // 타이머 완료 시 처리
                if state == .stopped && self.remainingTime <= 0 {
                    self.handleTimerCompletion()
                }
                
                self.sendSunscreenStateToCounterpart()
            }
            .store(in: &cancellables)
        
        timerManager.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.connectionStatus = status
            }
            .store(in: &cancellables)
    }
    
    /// 선크림 보호 시작
    func startSunscreenProtection(duration: TimeInterval = 120 * 60) {
        guard !isActive else {
            logger.warning("[\(self.deviceType)] Timer already active, ignoring start request")
            return
        }
        
        // TimerSyncManager를 통해 타이머 시작
        timerManager.start(duration: duration)
        totalDuration = duration
        
        logger.info("[\(self.deviceType)] Sunscreen protection started - Duration: \(duration)s")
        
        // 상대 기기에 즉시 상태 전송
        sendSunscreenStateToCounterpart()
    }
    
    /// 선크림 보호 중지
    func stopSunscreenProtection() {
        guard isActive else { return }
        
        timerManager.stop()
        
        logger.info("[\(self.deviceType)] Sunscreen protection stopped")
        
        // 상대 기기에 즉시 상태 전송
        sendSunscreenStateToCounterpart()
    }
    
    /// 선크림 보호 일시정지
    func pauseSunscreenProtection() {
        guard isActive else { return }
        
        timerManager.pause()
        
        logger.info("[\(self.deviceType)] Sunscreen protection paused")
        
        sendSunscreenStateToCounterpart()
    }
    
    /// 선크림 보호 재개
    func resumeSunscreenProtection() {
        guard timerManager.state == .paused else { return }
        
        timerManager.resume()
        
        logger.info("[\(self.deviceType)] Sunscreen protection resumed")
        
        sendSunscreenStateToCounterpart()
    }
    
    /// 타이머 리셋
    func resetTimer() {
        timerManager.stop()
        remainingTime = 0
        totalDuration = 120 * 60
        
        logger.info("[\(self.deviceType)] Timer reset")
        
        sendSunscreenStateToCounterpart()
    }
    
    /// 타이머 완료 처리
    private func handleTimerCompletion() {
        logger.info("[\(self.deviceType)] Sunscreen timer completed")
        
        // 완료 알림 전송
        NotificationCenter.default.post(name: .sunscreenTimerCompleted, object: nil)
        
        // watchOS에서만 햅틱 처리
#if os(watchOS)
        handleWatchTimerCompletion()
#endif
    }
    
#if os(watchOS)
    /// watchOS 타이머 완료 처리
    private func handleWatchTimerCompletion() {
        // 햅틱 피드백
        WKInterfaceDevice.current().play(.notification)
        
        // 백그라운드 새로고침 예약 (재도포 알림용)
        let reapplyDate = Date().addingTimeInterval(30 * 60) // 30분 후 재도포 알림
        
        // NSSecureCoding을 준수하는 NSDictionary 사용
        let userInfo = NSDictionary(dictionary: ["type": "sunscreen_reapply_reminder"])
        
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: reapplyDate,
            userInfo: userInfo,
            scheduledCompletion: { error in
                if let error = error {
                    self.logger.error("[Watch] Background refresh scheduling failed: \(error.localizedDescription)")
                } else {
                    self.logger.info("[Watch] Background refresh scheduled for sunscreen reapply reminder")
                }
            }
        )
        
        logger.info("[Watch] Timer completion handled - notification and haptic triggered")
    }
#endif
}
