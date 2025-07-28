//
//  WatchUvDoseViewModel.swift
//  TarTanningWatch Watch App
//
//  Created by taeni on 7/18/25.
//

// WatchUvDoseViewModel.swift 수정

import SwiftUI
import WatchConnectivity
import Combine

@Observable
class WatchUvDoseViewModel {
    var uvIndex: Int = 0
    var percentage: Int = 0
    var uvLevelText: String = "알 수 없음"
    var uvLevel: UVLevel = .safe
    var location: String = "위치 정보 없음"
    
    // 추가: 상태 관리
    var isRequestingData: Bool = false
    var lastUpdateTime: Date?
    
    private var cancellables = Set<AnyCancellable>()
    private let connectivityManager = WatchConnectivityManager.shared

    init() {
        setupWatchConnectivity()
        
        // 초기화 후 잠시 후 데이터 요청
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.requestDataFromiPhone()
        }
    }
    
    // MARK: - Watch Connectivity Setup
    private func setupWatchConnectivity() {
        // 컨텍스트 업데이트 수신
        connectivityManager.receivedContextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                guard let self = self else { return }
                print("⌚📱 [WatchUvDoseViewModel] Received context: \(context)")
                self.updateFrom(context: context)
            }
            .store(in: &cancellables)
        
        // 메시지 수신 (즉시 응답용)
        connectivityManager.receivedMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                print("⌚📱 [WatchUvDoseViewModel] Received message: \(message)")
                self.updateFrom(context: message)
            }
            .store(in: &cancellables)
        
        // 초기 컨텍스트 확인
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.connectivityManager.checkLastReceivedContext()
        }
    }

    // MARK: - Data Update
    private func updateFrom(context: [String: Any]) {
        print("🔍 [WatchUvDoseViewModel] Updating from context: \(context)")
        
        var hasUpdate = false
        
        if let index = context["uvIndex"] as? Int {
            self.uvIndex = index
            hasUpdate = true
            print("   • UV Index: \(index)")
        }
        
        if let percent = context["percentage"] as? Int {
            self.percentage = percent
            hasUpdate = true
            print("   • Percentage: \(percent)%")
        }
        
        if let level = context["uvLevel"] as? String {
            self.uvLevelText = level
            hasUpdate = true
            print("   • UV Level: \(level)")
        }
        
        if let levelRaw = context["uvLevelCode"] as? String,
           let parsed = UVLevel(rawValue: levelRaw) {
            self.uvLevel = parsed
            hasUpdate = true
            print("   • UV Level Code: \(levelRaw)")
        }
        
        if let location = context["location"] as? String {
            self.location = location
            hasUpdate = true
            print("   • Location: \(location)")
        }
        
        if hasUpdate {
            self.lastUpdateTime = Date()
            self.isRequestingData = false
            print("✅ [WatchUvDoseViewModel] Data updated successfully")
        } else {
            print("⚠️ [WatchUvDoseViewModel] No recognized data in context")
        }
    }
    
    // MARK: - Data Request Methods
    
    /// iPhone에서 최신 UV 데이터 요청
    func requestDataFromiPhone() {
        guard !isRequestingData else {
            print("⏸️ [WatchUvDoseViewModel] Already requesting data")
            return
        }
        
        print("📱 [WatchUvDoseViewModel] Requesting UV data from iPhone...")
        
        isRequestingData = true
        
        let requestMessage = [
            "action": "requestUVData",
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        connectivityManager.sendMessageToPhone(requestMessage)
        
        // 타임아웃 처리 (10초)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.isRequestingData {
                print("⏰ [WatchUvDoseViewModel] Data request timeout")
                self.isRequestingData = false
            }
        }
    }
    
    /// 데이터 새로고침
    func refreshData() {
        print("🔄 [WatchUvDoseViewModel] Data refresh requested")
        requestDataFromiPhone()
    }
    
    // MARK: - Status Check
    
    /// 데이터가 유효한지 확인
    var hasValidData: Bool {
        return uvIndex > 0 || percentage > 0 || location != "위치 정보 없음"
    }
    
    /// 데이터 상태 문자열
    var dataStatusText: String {
        if isRequestingData {
            return "데이터 요청 중..."
        } else if hasValidData {
            if let lastUpdate = lastUpdateTime {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "업데이트: \(formatter.string(from: lastUpdate))"
            } else {
                return "데이터 수신됨"
            }
        } else {
            return "데이터 없음"
        }
    }
    
    // MARK: - Debug Methods
    
    func logCurrentStatus() {
        print("🔍 [WatchUvDoseViewModel] Current Status:")
        print("   • UV Index: \(uvIndex)")
        print("   • Percentage: \(percentage)%")
        print("   • UV Level: \(uvLevelText)")
        print("   • Location: \(location)")
        print("   • Has Valid Data: \(hasValidData)")
        print("   • Is Requesting: \(isRequestingData)")
        print("   • Last Update: \(lastUpdateTime?.description ?? "None")")
    }
}

// MARK: - Mock Extension
extension WatchUvDoseViewModel {
    static var mock: WatchUvDoseViewModel {
        let viewModel = WatchUvDoseViewModel()
        viewModel.uvIndex = 6
        viewModel.percentage = 55
        viewModel.uvLevelText = "주의"
        viewModel.uvLevel = .caution
        viewModel.location = "포항시"
        viewModel.lastUpdateTime = Date()
        return viewModel
    }
}
