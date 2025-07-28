//
//  SunscreenViewModel+WatchSync.swift
//  TarTanning
//
//  Created by taeni on 7/28/25.
//

import Foundation
import Combine

// MARK: - Watch Connectivity & State Sync
extension SunscreenViewModel {
    
    /// Watch Connectivity 설정
    internal func setupWatchConnectivity() {
        let manager = WatchConnectivityManager.shared
        
        // WatchConnectivity를 통한 상태 수신
#if os(watchOS)
        manager.receivedContextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                guard let self = self else { return }
                self.updateFromContext(context: context)
                self.updateUVDataFromContext(context: context)
            }
            .store(in: &cancellables)
        
        manager.receivedMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                self.handleReceivedMessage(message)
                self.updateUVDataFromContext(context: message)
            }
            .store(in: &cancellables)
        
        // 초기 컨텍스트 확인
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            manager.checkLastReceivedContext()
        }
#endif
        
#if os(iOS)
        manager.messageFromWatchPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                self.handleReceivedMessage(message)
            }
            .store(in: &cancellables)
#endif
    }
    
    /// 연결 상태 업데이트
    internal func updateConnectionStatus() {
        let manager = WatchConnectivityManager.shared
        if manager.isReachable {
            connectionStatus = "연결됨"
        } else if manager.isActivated {
            connectionStatus = "비활성"
        } else {
            connectionStatus = "연결 안됨"
        }
    }
    
    /// 선크림 타이머 상태를 상대 기기로 전송
    internal func sendSunscreenStateToCounterpart() {
        let context = [
            "sunscreen_isActive": isActive,
            "sunscreen_remainingTime": remainingTime,
            "sunscreen_totalDuration": totalDuration,
            "sunscreen_timerState": timerState.rawValue,
            "sunscreen_deviceSource": deviceType,
            "sunscreen_timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        let manager = WatchConnectivityManager.shared
        
#if os(iOS)
        manager.sendContext(context)
        if manager.isReachable {
            manager.sendMessage(context)
        }
#else
        manager.sendMessageToPhone(context)
#endif
        
        logger.debug("[\(self.deviceType)] Sunscreen state sent to counterpart")
    }
    
    /// 선크림 타이머 상태 컨텍스트 업데이트
    private func updateFromContext(context: [String: Any]) {
        // 자신이 보낸 메시지는 무시
        if let deviceSource = context["sunscreen_deviceSource"] as? String,
           deviceSource == deviceType {
            return
        }
        
        // 너무 오래된 데이터는 무시 (30초 이상)
        if let timestamp = context["sunscreen_timestamp"] as? TimeInterval {
            let age = Date().timeIntervalSince1970 - timestamp
            guard age < 30 else {
                logger.warning("[\(self.deviceType)] Context too old: \(age)s")
                return
            }
        }
        
        isUpdatingFromRemote = true
        
        var hasTimerData = false
        
        if let active = context["sunscreen_isActive"] as? Bool {
            self.isActive = active
            hasTimerData = true
        }
        if let remaining = context["sunscreen_remainingTime"] as? TimeInterval {
            self.remainingTime = remaining
            hasTimerData = true
        }
        if let duration = context["sunscreen_totalDuration"] as? TimeInterval {
            self.totalDuration = duration
            hasTimerData = true
        }
        if let stateRaw = context["sunscreen_timerState"] as? String,
           let state = TimerState(rawValue: stateRaw) {
            self.timerState = state
            hasTimerData = true
        }
        
        // TimerSyncManager 상태도 동기화
        if hasTimerData {
            if isActive && timerManager.state != .running && remainingTime > 0 {
                syncLocalTimerWithRemote()
            } else if !isActive && timerManager.state == .running {
                timerManager.stop()
            }
            
            logger.info("[\(self.deviceType)] Updated context: Active=\(self.isActive), Remaining=\(self.remainingTime), State=\(self.timerState.rawValue)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isUpdatingFromRemote = false
        }
    }
    
    /// 수신된 메시지 처리
    private func handleReceivedMessage(_ message: [String: Any]) {
        // watchOS에서의 데이터 요청 처리 (iOS에서만)
        #if os(iOS)
        if message["action"] as? String == "requestUVDataRefresh" {
            print("📱 [SunscreenViewModel] Received UV data request from watch")
            handleDataRequest(from: message)
            return
        }
        #endif
        
        // 실시간 메시지 처리 (context와 동일한 로직)
        updateFromContext(context: message)
    }
    
    /// 원격 상태에 맞춰 로컬 타이머 동기화
    private func syncLocalTimerWithRemote() {
        guard remainingTime > 0 else { return }
        
        // 원격 상태에 맞춰 로컬 타이머 재시작
        let endTime = Date().addingTimeInterval(remainingTime)
        timerManager.storage.endTime = endTime
        timerManager.storage.state = .running
        
        logger.debug("[\(self.deviceType)] Local timer synced with remote state")
    }
}
