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
    
    // MARK: - Internal Properties (Extension에서 접근)
    internal var timerManager: TimerSyncManager
    internal var cancellables = Set<AnyCancellable>()
    internal var isUpdatingFromRemote = false
    internal let logger = Logger(subsystem: "com.example.TimerSync", category: "SunscreenTimer")
    
    // 디바이스 타입 구분
    internal nonisolated let deviceType: String = {
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
        setupUVDataReception()
        
        // iOS에서만 UV 데이터 동기화 시작
        #if os(iOS)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startUVDataSync()
        }
        #endif
        
        logger.info("[\(self.deviceType)] SunscreenViewModel initialized")
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let sunscreenTimerCompleted = Notification.Name("sunscreenTimerCompleted")
}
