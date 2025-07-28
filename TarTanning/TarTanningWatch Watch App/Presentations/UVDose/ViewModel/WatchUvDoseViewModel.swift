//
//  WatchUvDoseViewModel.swift
//  TarTanningWatch Watch App
//
//  Created by taeni on 7/18/25.
//

import SwiftUI
import WatchConnectivity
import Combine

@MainActor
final class WatchUvDoseViewModel: ObservableObject {
    enum UVLevel: String, CaseIterable {
        case safe = "안전"
        case caution = "주의"
        case danger = "위험"
        case bad = "매우위험"

        var color: Color {
            switch self {
            case .safe: return .gaugeBackgroundSafe
            case .caution: return .gaugeBackgroundCaution
            case .danger: return .gaugeBackgroundDanger
            case .bad: return .gaugeBackgroundBad
            }
        }
    }
    
    @Published var uvIndex: Int = 0
    @Published var medValue: Double = 0.0
    @Published var uvLevelText: String = "알 수 없음"
    @Published var uvLevel: UVLevel = .safe
    @Published var location: String = "위치 정보 없음"
    @Published var isConnected: Bool = false
    @Published var lastUpdateTime: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("@@@@@@@@@ [WatchUvDoseViewModel] Initializing...")
        
        // 순서 중요: WatchConnectivity 먼저 활성화
        activateWatchConnectivity()
        
        // 잠시 후 데이터 관찰 시작
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupDataObservation()
            
            // 초기 데이터 요청
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestInitialData()
            }
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Setup Methods
    
    private func activateWatchConnectivity() {
        #if os(watchOS)
        WatchConnectivityManager.shared.activateSession()
        
        // 연결 상태 모니터링
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.isConnected = WatchConnectivityManager.shared.isReachable
            }
        }
        #endif
    }
    
    private func setupDataObservation() {
        // 방법 1: SunscreenViewModel을 통한 데이터 수신 (기본)
        setupSunscreenViewModelObservation()
        
        // 방법 2: 직접 WatchConnectivity 수신 (백업)
        setupDirectConnectivityObservation()
    }
    
    private func setupSunscreenViewModelObservation() {
        print("📡 [WatchUvDoseViewModel] Setting up SunscreenViewModel observation...")
        
        // SunscreenViewModel의 UV 데이터 구독
        SunscreenViewModel.shared.$currentMEDValue
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMedValue in
                print("📊 [WatchUvDoseViewModel] MED value updated: \(newMedValue)")
                self?.medValue = newMedValue
                self?.lastUpdateTime = Date()
            }
            .store(in: &cancellables)
        
        SunscreenViewModel.shared.$currentUVIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newUvIndex in
                print("☀️ [WatchUvDoseViewModel] UV index updated: \(newUvIndex)")
                self?.uvIndex = Int(newUvIndex)
                self?.lastUpdateTime = Date()
            }
            .store(in: &cancellables)
        
        SunscreenViewModel.shared.$uvStatusLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatusLevel in
                print("🚦 [WatchUvDoseViewModel] Status level updated: \(newStatusLevel)")
                self?.updateUVLevel(newStatusLevel)
                self?.lastUpdateTime = Date()
            }
            .store(in: &cancellables)
        
        SunscreenViewModel.shared.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newLocation in
                print("📍 [WatchUvDoseViewModel] Location updated: \(newLocation)")
                self?.location = newLocation
                self?.lastUpdateTime = Date()
            }
            .store(in: &cancellables)
        
        // 연결 상태 구독
        SunscreenViewModel.shared.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isConnected = status == "연결됨"
            }
            .store(in: &cancellables)
    }
    
    private func setupDirectConnectivityObservation() {
        #if os(watchOS)
        print("📡 [WatchUvDoseViewModel] Setting up direct WatchConnectivity observation...")
        
        // WatchConnectivityManager 직접 구독 (백업용)
        WatchConnectivityManager.shared.receivedContextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                self?.handleDirectUVData(context)
            }
            .store(in: &cancellables)
        
        WatchConnectivityManager.shared.receivedMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleDirectUVData(message)
            }
            .store(in: &cancellables)
        #endif
    }
    
    // MARK: - Data Handling Methods
    
    private func updateUVLevel(_ statusLevel: String) {
        uvLevelText = statusLevel
        uvLevel = UVLevel(rawValue: statusLevel) ?? .safe
    }
    
    #if os(watchOS)
    private func handleDirectUVData(_ data: [String: Any]) {
        // UV 데이터가 포함된 메시지인지 확인
        guard data.keys.contains(where: { $0.hasPrefix("uv_") }) else { return }
        
        print("📱 [WatchUvDoseViewModel] Received direct UV data: \(data)")
        
        if let medValue = data["uv_medValue"] as? Double {
            self.medValue = medValue
        }
        if let uvIndex = data["uv_uvIndex"] as? Double {
            self.uvIndex = Int(uvIndex)
        }
        if let statusLevel = data["uv_statusLevel"] as? String {
            updateUVLevel(statusLevel)
        }
        if let location = data["uv_location"] as? String {
            self.location = location
        }
        
        lastUpdateTime = Date()
    }
    #endif
    
    // MARK: - Public Methods
    
    /// 데이터 새로고침 요청
    func requestDataRefresh() {
        #if os(watchOS)
        let refreshRequest = ["action": "requestUVDataRefresh", "timestamp": Date().timeIntervalSince1970] as [String:Any]
        WatchConnectivityManager.shared.sendMessageToPhone(refreshRequest)
        print("🔄 [WatchUvDoseViewModel] Data refresh requested")
        #endif
    }
    
    /// 초기 데이터 요청 (앱 처음 시작 시)
    private func requestInitialData() {
        #if os(watchOS)
        // SunscreenViewModel에서 데이터가 있는지 확인
        let sunscreenVM = SunscreenViewModel.shared
        
        print("🔍 [WatchUvDoseViewModel] Checking SunscreenViewModel data...")
        print("   MED: \(sunscreenVM.currentMEDValue)")
        print("   UV: \(sunscreenVM.currentUVIndex)")
        print("   Status: \(sunscreenVM.uvStatusLevel)")
        print("   Location: \(sunscreenVM.currentLocation)")
        
        // 데이터가 비어있으면 iPhone에 요청
        if sunscreenVM.currentMEDValue == 0.0 && sunscreenVM.currentUVIndex == 0.0 {
            print("📱 [WatchUvDoseViewModel] No data found, requesting from iPhone...")
            requestDataRefresh()
        } else {
            print("✅ [WatchUvDoseViewModel] Data already available from SunscreenViewModel")
        }
        #endif
    }
    
    /// 현재 데이터 상태 로그
    func logCurrentData() {
        print("📊 [WatchUvDoseViewModel] Current Data:")
        print("   UV Index: \(uvIndex)")
        print("   MED Value: \(String(format: "%.2f", medValue))")
        print("   Status: \(uvLevelText)")
        print("   Location: \(location)")
        print("   Connected: \(isConnected)")
        print("   Last Update: \(lastUpdateTime?.formatted() ?? "Never")")
    }
    
    // MARK: - Computed Properties for UI
    
    /// MED 값을 백분율로 변환
    var percentage: Int {
        // MED 값을 0-100 범위로 제한
        return Int(min(max(medValue, 0.0), 100.0))
    }
    
    /// UV 레벨에 따른 배경 색상
    var backgroundColorForLevel: Color {
        return uvLevel.color
    }
    
    /// 데이터 상태 표시를 위한 색상
    var statusColor: Color {
        if isConnected && lastUpdateTime != nil {
            return .green
        } else if lastUpdateTime != nil {
            return .orange
        } else {
            return .red
        }
    }
    
    /// 마지막 업데이트 시간 표시
    var lastUpdateString: String {
        guard let lastUpdate = lastUpdateTime else { return "데이터 없음" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "업데이트: \(formatter.string(from: lastUpdate))"
    }
}

// MARK: - Mock Data for Preview
extension WatchUvDoseViewModel {
    static var mock: WatchUvDoseViewModel {
        let viewModel = WatchUvDoseViewModel()
        viewModel.setupMockData()
        return viewModel
    }
    
    /// 테스트용 데이터 설정
    func setupMockData(
        uvIndex: Int = 6,
        medValue: Double = 55.0,
        uvLevel: UVLevel = .caution,
        location: String = "포항시"
    ) {
        self.uvIndex = uvIndex
        self.medValue = medValue
        self.uvLevelText = uvLevel.rawValue
        self.uvLevel = uvLevel
        self.location = location
        self.isConnected = true
        self.lastUpdateTime = Date()
    }
}
