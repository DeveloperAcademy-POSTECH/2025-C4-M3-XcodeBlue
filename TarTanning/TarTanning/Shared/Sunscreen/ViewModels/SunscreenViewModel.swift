//
//  SunscreenViewModel.swift
//  TarTanning (Shared Target)
//
//  Created by taeni on 7/19/25.
//

import Foundation
import SwiftUI
import Combine
import WatchConnectivity
import OSLog

#if os(watchOS)
import WatchKit
#endif

@MainActor
final class SunscreenViewModel: ObservableObject {
    static let shared = SunscreenViewModel()
    
    // MARK: - Timer Properties
    @Published var isActive: Bool = false
    @Published var remainingTime: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 120 * 60 // 2시간 기본값
    @Published var connectionStatus: String = "연결 안됨"
    @Published var timerState: TimerState = .stopped
    
    // MARK: - UV Data Properties
    @Published var currentMEDValue: Double = 0.0
    @Published var currentUVIndex: Double = 0.0
    @Published var uvStatusLevel: String = "안전"
    @Published var currentLocation: String = "위치 정보 없음"
    
    // MARK: - Computed Properties
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, (totalDuration - remainingTime) / totalDuration))
    }
    
    var isCompleted: Bool {
        remainingTime <= 0 && !isActive
    }
    
    var timeDisplayString: String {
        return remainingTime.timeDisplayString
    }
    
    // MARK: - Private Properties
    private var timerManager: TimerSyncManager
    private var cancellables = Set<AnyCancellable>()
    private var isUpdatingFromRemote = false
    private let logger = Logger(subsystem: "com.example.TimerSync", category: "SunscreenTimer")
    
    // 디바이스 타입 구분
    private nonisolated let deviceType: String = {
#if os(iOS)
        return "iPhone"
#else
        return "Watch"
#endif
    }()
    
    // MARK: - Initialization
    private init() {
        self.timerManager = TimerSyncManager.shared
        setupTimerObservers()
        setupWatchConnectivity()
        updateConnectionStatus()
        
        logger.info("[\(self.deviceType)] SunscreenViewModel initialized")
    }
    
    // MARK: - Timer Observer Setup
    private func setupTimerObservers() {
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
    
    // MARK: - Watch Connectivity Setup
    private func setupWatchConnectivity() {
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
    
    // MARK: - Connection Status
    private func updateConnectionStatus() {
        let manager = WatchConnectivityManager.shared
        if manager.isReachable {
            connectionStatus = "연결됨"
        } else if manager.isActivated {
            connectionStatus = "비활성"
        } else {
            connectionStatus = "연결 안됨"
        }
    }
    
    // MARK: - Timer Control Methods
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
    
    func stopSunscreenProtection() {
        guard isActive else { return }
        
        timerManager.stop()
        
        logger.info("[\(self.deviceType)] Sunscreen protection stopped")
        
        // 상대 기기에 즉시 상태 전송
        sendSunscreenStateToCounterpart()
    }
    
    func pauseSunscreenProtection() {
        guard isActive else { return }
        
        timerManager.pause()
        
        logger.info("[\(self.deviceType)] Sunscreen protection paused")
        
        sendSunscreenStateToCounterpart()
    }
    
    func resumeSunscreenProtection() {
        guard timerManager.state == .paused else { return }
        
        timerManager.resume()
        
        logger.info("[\(self.deviceType)] Sunscreen protection resumed")
        
        sendSunscreenStateToCounterpart()
    }
    
    func resetTimer() {
        timerManager.stop()
        remainingTime = 0
        totalDuration = 120 * 60
        
        logger.info("[\(self.deviceType)] Timer reset")
        
        sendSunscreenStateToCounterpart()
    }
    
    // MARK: - UV Data Management Methods
    
    /// UV 관련 데이터를 watchOS로 전송
    func sendUVDataToWatch(
        medValue: Double,
        uvIndex: Double,
        statusLevel: String,
        location: String
    ) {
        // 로컬 상태 업데이트
        self.currentMEDValue = medValue
        self.currentUVIndex = uvIndex
        self.uvStatusLevel = statusLevel
        self.currentLocation = location
        
        // watchOS로 전송
        sendUVDataToCounterpart()
        
        logger.info("[\(self.deviceType)] UV data sent to watch - MED: \(medValue), UV: \(uvIndex), Status: \(statusLevel), Location: \(location)")
    }
    
    /// UV 데이터만 별도로 전송하는 메서드
    private func sendUVDataToCounterpart() {
        let uvContext = [
            "uv_medValue": currentMEDValue,
            "uv_uvIndex": currentUVIndex,
            "uv_statusLevel": uvStatusLevel,
            "uv_location": currentLocation,
            "uv_deviceSource": deviceType,
            "uv_timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        let manager = WatchConnectivityManager.shared
        
#if os(iOS)
        manager.sendContext(uvContext)
        if manager.isReachable {
            manager.sendMessage(uvContext)
        }
#else
        manager.sendMessageToPhone(uvContext)
#endif
        
        logger.debug("[\(self.deviceType)] UV data context sent to counterpart")
    }
    
    /// UV 데이터 컨텍스트 업데이트 처리
    private func updateUVDataFromContext(context: [String: Any]) {
        // 자신이 보낸 메시지는 무시
        if let deviceSource = context["uv_deviceSource"] as? String,
           deviceSource == deviceType {
            return
        }
        
        // 너무 오래된 데이터는 무시 (30초 이상)
        if let timestamp = context["uv_timestamp"] as? TimeInterval {
            let age = Date().timeIntervalSince1970 - timestamp
            guard age < 30 else {
                logger.warning("[\(self.deviceType)] UV context too old: \(age)s")
                return
            }
        }
        
        var hasUVData = false
        
        // UV 데이터 업데이트
        if let medValue = context["uv_medValue"] as? Double {
            self.currentMEDValue = medValue
            hasUVData = true
        }
        if let uvIndex = context["uv_uvIndex"] as? Double {
            self.currentUVIndex = uvIndex
            hasUVData = true
        }
        if let statusLevel = context["uv_statusLevel"] as? String {
            self.uvStatusLevel = statusLevel
            hasUVData = true
        }
        if let location = context["uv_location"] as? String {
            self.currentLocation = location
            hasUVData = true
        }
        
        if hasUVData {
            logger.info("[\(self.deviceType)] UV data updated from context: MED=\(self.currentMEDValue), UV=\(self.currentUVIndex), Status=\(self.uvStatusLevel), Location=\(self.currentLocation)")
        }
    }
    
    // MARK: - Timer State Sync Methods
    
    /// 선크림 타이머 상태를 상대 기기로 전송
    private func sendSunscreenStateToCounterpart() {
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
    
    // MARK: - Timer Completion Handling
    
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

// MARK: - Notification Extension
extension Notification.Name {
    static let sunscreenTimerCompleted = Notification.Name("sunscreenTimerCompleted")
}

// MARK: - Preview & Test Support
extension SunscreenViewModel {
    /// Preview와 테스트용 Mock 데이터 설정
    func setupMockData(
        isActive: Bool = true,
        remainingTime: TimeInterval = 90 * 60,
        totalDuration: TimeInterval = 120 * 60,
        connectionStatus: String = "연결됨",
        medValue: Double = 45.0,
        uvIndex: Double = 6.0,
        statusLevel: String = "주의",
        location: String = "서울시"
    ) {
        self.isActive = isActive
        self.remainingTime = remainingTime
        self.totalDuration = totalDuration
        self.connectionStatus = connectionStatus
        self.currentMEDValue = medValue
        self.currentUVIndex = uvIndex
        self.uvStatusLevel = statusLevel
        self.currentLocation = location
    }
}
