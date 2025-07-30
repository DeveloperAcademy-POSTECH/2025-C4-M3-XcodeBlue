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
    
    @Published var isActive: Bool = false
    @Published var remainingTime: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 120 * 60 // 2시간 기본값
    @Published var connectionStatus: String = "연결 안됨"
    @Published var timerState: TimerState = .paused  // 추가된 프로퍼티
    
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
    
    private init() {
        self.timerManager = TimerSyncManager.shared
        setupTimerObservers()
        setupWatchConnectivity()
        updateConnectionStatus()
        
        // 오래된 타이머 기간 정리
        TimerSPFManager.shared.cleanupOldPeriods()
        
        logger.info("[\(self.deviceType)] SunscreenViewModel initialized")
    }
    
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
                self.timerState = state  // timerState 업데이트
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
    
    private func setupWatchConnectivity() {
        let manager = WatchConnectivityManager.shared
        
        // WatchConnectivity를 통한 상태 수신
#if os(watchOS)
        manager.receivedContextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                guard let self = self else { return }
                self.updateFromContext(context: context)
            }
            .store(in: &cancellables)
        
        manager.receivedMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                self.handleReceivedMessage(message)
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
    
    func startSunscreenProtection(duration: TimeInterval = 120 * 60) {
        guard !isActive else {
            logger.warning("[\(self.deviceType)] Timer already active, ignoring start request")
            return
        }
        
        // SPF 레벨 가져오기 (UserDefaults에서)
        let spfLevel = Double(UserDefaults.standard.integer(forKey: "selectedSPFLevel"))
        
        // TimerSPFManager에 활성화 기간 추가
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(duration)
        TimerSPFManager.shared.addActivePeriod(
            startTime: startTime,
            endTime: endTime,
            spfLevel: spfLevel
        )
        
        // TimerSyncManager를 통해 타이머 시작
        timerManager.start(duration: duration)
        totalDuration = duration
        
        logger.info("[\(self.deviceType)] Sunscreen protection started - Duration: \(duration)s, SPF: \(spfLevel)")
        
        // 상대 기기에 즉시 상태 전송
        sendSunscreenStateToCounterpart()
    }
    
    func stopSunscreenProtection() {
        guard isActive else { return }
        
        // TimerSPFManager에서 현재 활성화 기간의 종료 시간 업데이트
        TimerSPFManager.shared.updateCurrentPeriodEndTime(to: Date())
        
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
    
    private func sendSunscreenStateToCounterpart() {
        let context = [
            "sunscreen_isActive": isActive,
            "sunscreen_remainingTime": remainingTime,
            "sunscreen_totalDuration": totalDuration,
            "sunscreen_timerState": timerState.rawValue,  // timerState 추가
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
        
        if let active = context["sunscreen_isActive"] as? Bool {
            self.isActive = active
        }
        if let remaining = context["sunscreen_remainingTime"] as? TimeInterval {
            self.remainingTime = remaining
        }
        if let duration = context["sunscreen_totalDuration"] as? TimeInterval {
            self.totalDuration = duration
        }
        if let stateRaw = context["sunscreen_timerState"] as? String,
           let state = TimerState(rawValue: stateRaw) {
            self.timerState = state  // timerState 동기화
        }
        
        // TimerSyncManager 상태도 동기화
        if isActive && timerManager.state != .running && remainingTime > 0 {
            syncLocalTimerWithRemote()
        } else if !isActive && timerManager.state == .running {
            timerManager.stop()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isUpdatingFromRemote = false
        }
    }
    
    private func handleReceivedMessage(_ message: [String: Any]) {
        // 실시간 메시지 처리 (context와 동일한 로직)
        updateFromContext(context: message)
    }
    
    private func syncLocalTimerWithRemote() {
        guard remainingTime > 0 else { return }
        
        // 원격 상태에 맞춰 로컬 타이머 재시작
        let endTime = Date().addingTimeInterval(remainingTime)
        timerManager.storage.endTime = endTime
        timerManager.storage.state = .running
        
        logger.debug("[\(self.deviceType)] Local timer synced with remote state")
    }
    
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

extension Notification.Name {
    static let sunscreenTimerCompleted = Notification.Name("sunscreenTimerCompleted")
}

extension SunscreenViewModel {
    /// Preview와 테스트용 Mock 데이터 설정
    func setupMockData(
        isActive: Bool = true,
        remainingTime: TimeInterval = 90 * 60,
        totalDuration: TimeInterval = 120 * 60,
        connectionStatus: String = "연결됨"
    ) {
        self.isActive = isActive
        self.remainingTime = remainingTime
        self.totalDuration = totalDuration
        self.connectionStatus = connectionStatus
    }
}

#if DEBUG
@MainActor
final class MockSunscreenViewModel: ObservableObject {
    @Published var isActive: Bool
    @Published var remainingTime: TimeInterval
    @Published var totalDuration: TimeInterval
    @Published var connectionStatus: String
    @Published var timerState: TimerState  // Mock에도 timerState 추가
    
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
    
    init(
        isActive: Bool = false,
        remainingTime: TimeInterval = 0,
        totalDuration: TimeInterval = 120 * 60,
        connectionStatus: String = "연결 안됨",
        timerState: TimerState = .stopped
    ) {
        self.isActive = isActive
        self.remainingTime = remainingTime
        self.totalDuration = totalDuration
        self.connectionStatus = connectionStatus
        self.timerState = timerState
    }
    
    // Mock 메서드들 (실제 동작 안함)
    func startSunscreenProtection(duration: TimeInterval = 120 * 60) {
        isActive = true
        remainingTime = duration
        totalDuration = duration
        timerState = .running
    }
    
    func stopSunscreenProtection() {
        isActive = false
        remainingTime = 0
        timerState = .stopped
    }
    
    func resetTimer() {
        isActive = false
        remainingTime = 0
        totalDuration = 120 * 60
        timerState = .stopped
    }
    
    // 자주 사용되는 Mock 상태들
    static var active: MockSunscreenViewModel {
        MockSunscreenViewModel(
            isActive: true,
            remainingTime: 75 * 60,        // 1시간 15분 남음
            totalDuration: 120 * 60,       // 총 2시간
            connectionStatus: "연결됨",
            timerState: .running
        )
    }
    
    static var completed: MockSunscreenViewModel {
        MockSunscreenViewModel(
            isActive: false,
            remainingTime: 0,              // 완료됨
            totalDuration: 120 * 60,       // 총 2시간
            connectionStatus: "연결됨",
            timerState: .stopped
        )
    }
    
    static var disconnected: MockSunscreenViewModel {
        MockSunscreenViewModel(
            isActive: true,
            remainingTime: 45 * 60,        // 45분 남음
            totalDuration: 120 * 60,       // 총 2시간
            connectionStatus: "연결 안됨",
            timerState: .running
        )
    }
    
    static var inactive: MockSunscreenViewModel {
        MockSunscreenViewModel(
            isActive: false,
            remainingTime: 0,
            totalDuration: 120 * 60,
            connectionStatus: "비활성",
            timerState: .stopped
        )
    }
}
#endif
