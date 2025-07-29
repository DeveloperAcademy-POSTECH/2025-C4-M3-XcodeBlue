//
//  WatchDashboardSyncManager.swift
//  TarTanningWatch Watch App
//
//  Created by Assistant on 7/29/25.
//

import Foundation
import SwiftUI
import Combine
import WatchConnectivity

@MainActor
final class WatchDashboardSyncService: ObservableObject {
    static let shared = WatchDashboardSyncService()
    
    // MARK: - Published Properties
    @Published var currentCityName: String = "위치 확인 중"
    @Published var currentUVIndex: Double = 0.0
    @Published var todayUVProgressRate: Double = 0.0
    @Published var totalUVDose: Double = 0.0
    @Published var totalSunlight: Int = 0
    @Published var lastUpdated: Date?
    @Published var connectionStatus: String = "연결 안됨"
    
    // MARK: - Computed Properties
    var uvProgressPercentage: Int {
        return Int(todayUVProgressRate * 100)
    }
    
    var uvLevel: UVLevel {
        switch todayUVProgressRate {
        case 0.0..<0.3:
            return .safe
        case 0.3..<0.5:
            return .caution
        case 0.5..<0.7:
            return .danger
        default:
            return .extreme
        }
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var isUpdatingFromRemote = false
    
    private init() {
        setupWatchConnectivity()
        updateConnectionStatus()
        print("⌚ [WatchDashboardSyncManager] Initialized")
    }
    
    // MARK: - WatchConnectivity Setup
    private func setupWatchConnectivity() {
        let manager = WatchConnectivityManager.shared
        
        // Context 수신 (실시간 상태 업데이트)
        manager.receivedContextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                self?.updateFromiOSContext(context)
            }
            .store(in: &cancellables)
        
        // Message 수신 (일회성 메시지)
        manager.receivedMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.updateFromiOSContext(message)
            }
            .store(in: &cancellables)
        
        // 초기 컨텍스트 확인 (지연 실행)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            manager.checkLastReceivedContext()
        }
    }
    
    // MARK: - Data Update Methods
    private func updateFromiOSContext(_ context: [String: Any]) {
        guard !isUpdatingFromRemote else { return }
        isUpdatingFromRemote = true
        
        var hasUpdates = false
        
        // 도시명 업데이트
        if let cityName = context["dashboard_currentCityName"] as? String,
           cityName != self.currentCityName {
            self.currentCityName = cityName
            hasUpdates = true
        }
        
        // UV 지수 업데이트
        if let uvIndex = context["dashboard_currentUVIndex"] as? Double,
           uvIndex != self.currentUVIndex {
            self.currentUVIndex = uvIndex
            hasUpdates = true
        }
        
        // UV 진행률 업데이트
        if let progressRate = context["dashboard_todayUVProgressRate"] as? Double,
           progressRate != self.todayUVProgressRate {
            self.todayUVProgressRate = progressRate
            hasUpdates = true
        }
        
        // 총 UVDose
        if let uvDose = context["dashboard_totalUVDose"] as? Double,
           uvDose != self.totalUVDose {
            self.totalUVDose = uvDose
            hasUpdates = true
        }
        
        
        if let totalSunlight = context["dashboard_totalSunlightMinutes"] as? Int,
           totalSunlight != self.totalSunlight {
            self.totalSunlight = totalSunlight
            hasUpdates = true
        }
        
        // 마지막 업데이트 시간
        if let timestamp = context["dashboard_lastUpdated"] as? TimeInterval {
            self.lastUpdated = Date(timeIntervalSince1970: timestamp)
            hasUpdates = true
        }
        
        if hasUpdates {
            print("⌚ [WatchDashboardSyncManager] Updated from iOS:")
            print("   • City: \(currentCityName)")
            print("   • UV Index: \(String(format: "%.1f", currentUVIndex))")
            print("   • Progress: \(uvProgressPercentage)%")
            print("   • Level: \(uvLevel)")
        }
        
        // 연결 상태 업데이트
        updateConnectionStatus()
        
        // 업데이트 플래그 해제
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isUpdatingFromRemote = false
        }
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
    
    // MARK: - Manual Refresh
    func requestDataFromiPhone() {
        print("⌚ [WatchDashboardSyncManager] Requesting data from iPhone")
        
        let requestMessage: [String: Any] = [
            "request_dashboard_sync": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        WatchConnectivityManager.shared.sendMessageToPhone(requestMessage)
    }
}

// MARK: - UV Level Enum
enum UVLevel {
    case safe
    case caution
    case danger
    case extreme
    
    var color: Color {
        switch self {
        case .safe:
            return .gaugeBackgroundSafe
        case .caution:
            return .gaugeBackgroundCaution
        case .danger:
            return .gaugeBackgroundDanger
        case .extreme:
            return .gaugeBackgroundBad
        }
    }
    
    var description: String {
        switch self {
        case .safe:
            return "낮은 수준"
        case .caution:
            return "보통 수준"
        case .danger:
            return "주의 수준"
        case .extreme:
            return "높은 수준"
        }
    }
}
