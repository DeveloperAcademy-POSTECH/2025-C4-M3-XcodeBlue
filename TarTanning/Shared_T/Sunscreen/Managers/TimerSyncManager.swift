//
//  TimerNotificationManager.swift.swift
//  TarTanning
//
//  Created by taeni on 7/17/25.
//

import Foundation
import SwiftUI
import WatchConnectivity

@MainActor
final class TimerSyncManager: NSObject, ObservableObject {
    static let shared = TimerSyncManager()
    
    private let storage = TimerStorage.shared
    private var timer: Timer?
    
    @Published var remainingTime: TimeInterval = 0
    @Published var state: TimerState = .stopped
    @Published var connectionStatus: String = "연결 안됨"
    
    // 디바이스 구분 (nonisolated에서 접근 가능하도록)
    private nonisolated let deviceType: String = {
#if os(iOS)
        return "iPhone"
#else
        return "Watch"
#endif
    }()
    
    // WatchConnectivity
    private var session: WCSession?
    
    override private init() {
        super.init()
        setupWatchConnectivity()
        loadInitialState()
        startTimerLoop() // 모든 기기에서 타이머 실행
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("[\(deviceType)] WatchConnectivity is not supported")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        
        print("[\(deviceType)] WatchConnectivity setup initiated")
    }
    
    // MARK: - Timer Management
    private func loadInitialState() {
        self.state = storage.state
        if let endTime = storage.endTime {
            updateRemainingTime(endTime: endTime)
            if remainingTime <= 0 && state == .running {
                completeTimer()
            }
        }
        
        print("[\(deviceType)] Initial state loaded - State: \(state), Remaining: \(remainingTime)")
    }
    
    private func startTimerLoop() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            
            Task { @MainActor in
                self.updateTimer()
            }
        }
        
        print("[\(deviceType)] Timer loop started")
    }
    
    private func updateTimer() {
        // 일시정지 상태에서는 타이머 업데이트 하지 않음
        guard state == .running else { return }
        
        guard let endTime = storage.endTime else {
            completeTimer()
            return
        }
        
        updateRemainingTime(endTime: endTime)
        
        if remainingTime <= 0 {
            completeTimer()
        }
    }
    
    private func updateRemainingTime(endTime: Date) {
        let remaining = endTime.timeIntervalSinceNow
        remainingTime = max(remaining, 0)
    }
    
    private func completeTimer() {
        storage.clear()
        state = .stopped
        remainingTime = 0
        
        // watchOS에서 알림 및 햅틱 처리
#if os(watchOS)
        Task {
            // 즉시 알림 표시
            WatchTimerNotificationManager.shared.showImmediateNotification()
            
            // 햅틱 피드백
            WatchHapticManager.shared.playTimerCompletionHaptic()
            
            print("[Watch] Timer completed - notification and haptic triggered")
        }
#endif
        
        // 상대 기기에 완료 알림
        sendTimerSync(endTime: Date(), state: .stopped, isCompletion: true)
    }
    
    // Public Timer Controls
    func start(duration: TimeInterval) {
        let endTime = Date().addingTimeInterval(duration)
        
        // 로컬 상태 업데이트
        storage.endTime = endTime
        storage.state = .running
        state = .running
        updateRemainingTime(endTime: endTime)
        
        // 상대 기기에 동기화
        sendTimerSync(endTime: endTime, state: .running)
    }
    
    func stop() {
        storage.clear()
        state = .stopped
        remainingTime = 0
        
        // 상대 기기에 동기화
        sendTimerSync(endTime: Date(), state: .stopped)
    }
    
    func pause() {
        guard state == .running else { return }
        
        storage.state = .paused
        state = .paused
        
        // 일시정지 시점 고정
        let pausedEndTime = Date().addingTimeInterval(remainingTime)
        storage.endTime = pausedEndTime
        
        sendTimerSync(endTime: pausedEndTime, state: .paused)
    }
    
    func resume() {
        guard state == .paused else { return }
        
        // 일시정지된 남은 시간으로 새로운 endTime 계산
        let newEndTime = Date().addingTimeInterval(remainingTime)
        storage.endTime = newEndTime
        storage.state = .running
        state = .running
        
        sendTimerSync(endTime: newEndTime, state: .running)
    }
    
    // MARK: - Synchronization
    private struct TimerSyncData: Codable {
        let endTime: Date
        let state: TimerState
        let deviceSource: String
        let timestamp: Date
        let isCompletion: Bool
        
        init(endTime: Date, state: TimerState, deviceSource: String, isCompletion: Bool = false) {
            self.endTime = endTime
            self.state = state
            self.deviceSource = deviceSource
            self.timestamp = Date()
            self.isCompletion = isCompletion
        }
    }
    
    private func sendTimerSync(endTime: Date, state: TimerState, isCompletion: Bool = false) {
        guard let session = session else {
            print("[\(deviceType)] No WCSession available")
            return
        }
        
        let syncData = TimerSyncData(
            endTime: endTime,
            state: state,
            deviceSource: deviceType,
            isCompletion: isCompletion
        )
        
        do {
            let data = try JSONEncoder().encode(syncData)
            let message = ["timerSync": data]
            
            // 실시간 메시지 전송 (상대방이 활성 상태일 때)
            if session.isReachable {
                session.sendMessage(message, replyHandler: { _ in
                    print("[\(self.deviceType)] Sync sent successfully")
                }, errorHandler: { error in
                    print("[\(self.deviceType)] Sync failed: \(error.localizedDescription)")
                })
            }
            
            // Application Context로도 전송 (백그라운드 대응)
            let context = [
                "endTime": endTime.timeIntervalSince1970,
                "state": state.rawValue,
                "deviceSource": deviceType,
                "timestamp": Date().timeIntervalSince1970,
                "isCompletion": isCompletion
            ] as [String: Any]
            
            try session.updateApplicationContext(context)
            print("[\(deviceType)] Context updated")
            
        } catch {
            print("[\(deviceType)] Failed to send sync: \(error.localizedDescription)")
        }
    }
    
    // 수신된 동기화 데이터 처리
    private func handleReceivedSync(_ syncData: TimerSyncData) {
        // 자신이 보낸 메시지는 무시
        guard syncData.deviceSource != deviceType else {
            print("[\(deviceType)] Ignoring own message")
            return
        }
        
        print("[\(deviceType)] Received sync from \(syncData.deviceSource): \(syncData.state)")
        
        // 너무 오래된 데이터는 무시 (5초 이상)
        let age = Date().timeIntervalSince1970 - syncData.timestamp.timeIntervalSince1970
        guard age < 5 else {
            print("[\(deviceType)] Sync data too old: \(age)s")
            return
        }
        
        // 로컬 상태 업데이트
        storage.endTime = syncData.state == .stopped ? nil : syncData.endTime
        storage.state = syncData.state
        state = syncData.state
        
        if syncData.state == .stopped {
            remainingTime = 0
        } else {
            updateRemainingTime(endTime: syncData.endTime)
        }
        
        print("[\(deviceType)] State synchronized: \(state), Remaining: \(remainingTime)")
    }
    
    private func updateConnectionStatus(_ status: String) {
        connectionStatus = status
        print("[\(deviceType)] Connection: \(status)")
    }
}

// MARK: - WCSessionDelegate
extension TimerSyncManager: WCSessionDelegate {
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let deviceName = deviceType  // 로컬 복사
        DispatchQueue.main.async {
            print("[\(deviceName)] WCSession activated - State: \(activationState.rawValue)")
            
            switch activationState {
            case .activated:
                self.updateConnectionStatus("연결됨")
                // 연결 즉시 현재 상태 동기화 요청
                if let endTime = self.storage.endTime, self.state != .stopped {
                    self.sendTimerSync(endTime: endTime, state: self.state)
                }
            case .inactive:
                self.updateConnectionStatus("비활성")
            case .notActivated:
                self.updateConnectionStatus("미활성화")
            @unknown default:
                self.updateConnectionStatus("알 수 없음")
            }
            
            if let error = error {
                print("[\(deviceName)] WCSession activation error: \(error.localizedDescription)")
            }
        }
    }
    
#if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        let deviceName = deviceType
        DispatchQueue.main.async {
            print("[\(deviceName)] WCSession became inactive")
            self.updateConnectionStatus("비활성")
        }
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        let deviceName = deviceType
        DispatchQueue.main.async {
            print("[\(deviceName)] WCSession deactivated - Reactivating...")
            self.updateConnectionStatus("재연결 중")
            WCSession.default.activate()
        }
    }
#endif
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable  // 미리 값을 추출
        DispatchQueue.main.async {
            let status = isReachable ? "연결됨" : "연결 안됨"
            self.updateConnectionStatus(status)
            print("[\(self.deviceType)] Reachability changed: \(status)")
        }
    }
    
    // 실시간 메시지 수신
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let syncData = message["timerSync"] as? Data else {
            print("[\(deviceType)] Invalid message format")
            return
        }
        
        do {
            let timerSync = try JSONDecoder().decode(TimerSyncData.self, from: syncData)
            DispatchQueue.main.async {
                self.handleReceivedSync(timerSync)
            }
        } catch {
            print("[\(deviceType)] Failed to decode sync message: \(error.localizedDescription)")
        }
    }
    
    // 백그라운드 컨텍스트 수신
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.handleApplicationContext(applicationContext)
        }
    }
    
    private func handleApplicationContext(_ context: [String: Any]) {
        guard let endTimeInterval = context["endTime"] as? TimeInterval,
              let stateRaw = context["state"] as? String,
              let state = TimerState(rawValue: stateRaw),
              let deviceSource = context["deviceSource"] as? String,
              let timestamp = context["timestamp"] as? TimeInterval else {
            print("[\(deviceType)] Invalid context data")
            return
        }
        
        // 자신이 보낸 컨텍스트는 무시
        guard deviceSource != deviceType else {
            return
        }
        
        // 너무 오래된 데이터는 무시
        let age = Date().timeIntervalSince1970 - timestamp
        guard age < 30 else {
            print("[\(deviceType)] Context too old: \(age)s")
            return
        }
        
        print("[\(deviceType)] Received context from \(deviceSource): \(state)")
        
        let endTime = endTimeInterval > 0 ? Date(timeIntervalSince1970: endTimeInterval) : Date()
        let syncData = TimerSyncData(endTime: endTime, state: state, deviceSource: deviceSource)
        
        handleReceivedSync(syncData)
    }
}
