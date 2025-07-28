//
//  DashboardViewModel.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentWeather: LocationWeather?
    @Published var todayTotalSunlightMinutes: Int = 0
    @Published var todayUVExposure: DailyUVExpose?
    @Published var todayMEDValue: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    let modelContext: ModelContext
    
    // MARK: - UseCase Factory Methods (메모리 안전)
    internal func getWeatherDataUseCase() -> GetWeatherDataUseCase {
        return GetWeatherDataUseCase(modelContext: modelContext)
    }
    
    internal func syncWeatherDataUseCase() -> SyncWeatherDataUseCase {
        return SyncWeatherDataUseCase(modelContext: modelContext)
    }
    
    internal func syncUVDataFromHealthKitUseCase() -> SyncUVDataFromHealthKitUseCase {
        return SyncUVDataFromHealthKitUseCase(modelContext: modelContext)
    }
    
    internal func getTodayUVExposureUseCase() -> GetTodayUVExposureUseCase {
        return GetTodayUVExposureUseCase(modelContext: modelContext)
    }
    
    internal func calculateAndSaveUVDoseUseCase() -> CalculateAndSaveUVDoseUseCase {
        return CalculateAndSaveUVDoseUseCase(modelContext: modelContext)
    }
    
    internal func getUserProfileUseCase() -> GetUserProfileUseCase {
        return GetUserProfileUseCase()
    }
    
    // MARK: - Private Properties
    private var currentLocation = LocationInfo.mockSeoul
    private var cancellables = Set<AnyCancellable>()
    private var isHealthKitSyncing = false
    private var lastHealthKitSyncTime: Date = Date.distantPast
    
    // 캐시된 사용자 프로필 (중복 호출 방지)
    private var cachedUserProfile: UserProfile?
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // 사용자 프로필 미리 로드 (캐싱)
        _ = getUserProfile()
        
        // HealthKit 관찰 시작
        HealthKitQueryFetchManager.shared.startObservingHealthKitUpdates()
        
        // HealthKit 업데이트 알림 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHealthKitUpdate),
            name: .healthKitDataUpdated,
            object: nil
        )
        
        // 사용자 프로필 변경 알림 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserProfileUpdate),
            name: UserDefaultManager.userProfileDidChangeNotification,
            object: nil
        )
        
        // SwiftData 변경사항 감지 설정
        setupSwiftDataObservation()
    }
    
    deinit {
        // HealthKit 관찰 중지
        Task { @MainActor in
            HealthKitQueryFetchManager.shared.stopObservingHealthKitUpdates()
        }
        
        // 알림 구독 해제
        NotificationCenter.default.removeObserver(self)
        
        // Combine 구독 해제
        cancellables.removeAll()
    }
    
    // MARK: - Computed Properties
    var currentUVIndex: Double {
        guard let weather = currentWeather else { return 0.0 }
        return getWeatherDataUseCase().getCurrentUVIndex(from: weather)
    }
    
    var currentTemperature: Int {
        guard let weather = currentWeather else { return 0 }
        return Int(getWeatherDataUseCase().getCurrentTemperature(from: weather))
    }
    
    var currentCityName: String {
        return currentWeather?.city ?? currentLocation.city
    }
    
    var todayUVProgressRate: Double {
        guard let dailyUV = todayUVExposure else { return 0.0 }
        
        // 캐시된 사용자 프로필에서 maxMED 가져오기
        let maxMED = getMaxMED()
        
        // 현재 UV Dose를 maxMED로 나누어 진행률 계산 (100%를 넘을 수 있음)
        let progressRate = dailyUV.totalUVDose / maxMED
        
        // 0.0 이상으로 제한 (100%를 넘을 수 있음)
        return max(progressRate, 0.0)
    }
    
    // MARK: - Weather Feature Methods
    
    /// 날씨 데이터 로드
    func loadWeatherData() {
        isLoading = true
        errorMessage = nil
        
        print("🔄 [DashboardViewModel] Loading weather data for \(currentLocation.city)")
        
        Task { @MainActor in
            do {
                let weatherData = try await syncWeatherDataUseCase().syncWeatherData(
                    for: currentLocation,
                    type: .syncAll
                )
                
                self.currentWeather = weatherData
                self.isLoading = false
                self.logCurrentWeatherInfo()
                
                // watch 로 데이터 보내기
                self.syncUVDataToWatch()
                
            } catch {
                self.isLoading = false
                if let weatherError = error as? WeatherManagerError {
                    self.errorMessage = weatherError.localizedDescription
                } else {
                    self.errorMessage = "날씨 정보를 불러올 수 없습니다"
                }
            }
        }
    }
    
    /// 위치 변경 시 날씨 데이터 업데이트
    func updateLocation(_ newLocation: LocationInfo) {
        print("📍 [DashboardViewModel] Location update to \(newLocation.city)")
        currentLocation = newLocation
        
        Task { @MainActor in
            do {
                let weatherData = try await syncWeatherDataUseCase().syncWeatherData(
                    for: newLocation,
                    type: .syncByLocationChange
                )
                
                self.currentWeather = weatherData
                self.calculateTotalSunlightMinutes()
            } catch {
                if let weatherError = error as? WeatherManagerError {
                    self.errorMessage = weatherError.localizedDescription
                }
            }
        }
    }
    
    /// 날씨 데이터 비동기 로드 (UV Dose 계산을 위해 필요)
    @MainActor func loadWeatherDataAsync() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let weatherData = try await syncWeatherDataUseCase().syncWeatherData(
                for: currentLocation,
                type: .syncAll
            )
            
            self.currentWeather = weatherData
            self.isLoading = false
            self.logCurrentWeatherInfo()
            
        } catch {
            self.isLoading = false
            if let weatherError = error as? WeatherManagerError {
                self.errorMessage = weatherError.localizedDescription
            } else {
                self.errorMessage = "날씨 정보를 불러올 수 없습니다"
            }
        }
    }
    
    // MARK: - UV Exposure Feature Methods
    
    /// HealthKit에서 UV 노출량 데이터 로드
    func loadUVExposureData() {
        // 이미 동기화 중이면 스킵
        guard !isHealthKitSyncing else {
            return
        }
        isHealthKitSyncing = true
        
        Task { @MainActor in
            defer {
                isHealthKitSyncing = false
                lastHealthKitSyncTime = Date()
            }
            
            do {
                // 1. HealthKit에서 일광시간 데이터 동기화
                print("📱 [DashboardViewModel] Step 1: Syncing HealthKit data...")
                try await syncUVDataFromHealthKitUseCase().syncTodaySunlightFromHealthKit()
                print("✅ [DashboardViewModel] Step 1: HealthKit sync completed")
                
                // 2. 오늘의 UV 노출량 조회
                print("📱 [DashboardViewModel] Step 2: Fetching today's UV exposure...")
                let todayUVExposure = try await getTodayUVExposureUseCase().getTodayDailyUVExposure()
                
                self.todayUVExposure = todayUVExposure
                
                // HealthKit에서 가져온 실제 일광시간으로 업데이트
                let actualSunlightMinutes = getTodayUVExposureUseCase().getTotalSunlightMinutes(from: todayUVExposure)
                self.todayTotalSunlightMinutes = Int(actualSunlightMinutes)
                
                // UV Dose 값 업데이트
                let newMEDValue = getTodayUVExposureUseCase().getTotalUVDose(from: todayUVExposure)
                self.todayMEDValue = newMEDValue
                
                print("✅ [DashboardViewModel] UV exposure data loaded: \(self.todayTotalSunlightMinutes) minutes, \(String(format: "%.4f", self.todayMEDValue)) J/m²")
                
                // watch 로 데이터 보내기
                self.syncUVDataToWatch()
                
            } catch {
                // 타임아웃 에러는 조용히 처리
                if let healthKitError = error as? HealthKitError,
                   case .queryFailed(let underlyingError) = healthKitError,
                   underlyingError.localizedDescription.contains("timeout") {
                    print("⏰ [DashboardViewModel] HealthKit query timeout in loadUVExposureData")
                } else if error.localizedDescription.contains("timeout") {
                    print("⏰ [DashboardViewModel] HealthKit timeout in loadUVExposureData")
                } else {
                    // 더 자세한 에러 정보 출력
                    if let healthKitError = error as? HealthKitError {
                        print("🔍 [DashboardViewModel] HealthKit Error: \(healthKitError.localizedDescription)")
                        
                        switch healthKitError {
                        case .authorizationDenied:
                            self.errorMessage = "HealthKit 권한이 필요합니다. 설정에서 권한을 허용해주세요."
                        case .notAvailable:
                            self.errorMessage = "이 기기에서는 HealthKit을 사용할 수 없습니다."
                        default:
                            self.errorMessage = "UV 노출량 데이터를 불러올 수 없습니다: \(healthKitError.localizedDescription)"
                        }
                    } else {
                        self.errorMessage = "UV 노출량 데이터를 불러올 수 없습니다"
                    }
                }
            }
        }
    }
    
    /// UV Dose 재계산 (기존 데이터에 대한 UV Dose 업데이트)
    func recalculateUVDose() {
        Task { @MainActor in
            do {
                // UV Dose 재계산 및 저장 (매개변수 제거)
                try await calculateAndSaveUVDoseUseCase().calculateAndSaveTodayUVDose()
                
                // 업데이트된 UV 노출량 조회
                let updatedUVExposure = try await getTodayUVExposureUseCase().getTodayDailyUVExposure()
                
                self.todayUVExposure = updatedUVExposure
                self.todayMEDValue = getTodayUVExposureUseCase().getTotalUVDose(from: updatedUVExposure)
                // watch 로 데이터 보내기
                self.syncUVDataToWatch()
            } catch {
                self.errorMessage = "UV Dose 재계산에 실패했습니다"
            }
        }
    }
    
    // MARK: - Dashboard Orchestration Methods
    
    /// 모든 대시보드 데이터 로드 (Weather + UV Exposure)
    func loadAllDashboardData() {
        Task { @MainActor in
            // 1. 날씨 데이터 먼저 로드 (UV Dose 계산을 위해 필요)
            await loadWeatherDataAsync()
            
            // 2. UV 노출량 데이터 로드 (이미 UV Dose 계산 포함)
            loadUVExposureData()
        }
    }
    
    /// 전체 데이터 새로고침 (Pull-to-Refresh용)
    @MainActor func refreshAllData() async {
        // 1. 날씨 데이터 먼저 새로고침 (UV Dose 계산을 위해 필요)
        await loadWeatherDataAsync()
        
        // 2. UV 노출량 데이터 새로고침 (이미 UV Dose 계산 포함)
        loadUVExposureData()
    }
    
    // MARK: - Weekly Summary Feature Methods
    
    /// 주간 UV 진행률 계산 (오늘 제외 최근 7일)
    var weeklyUVProgressRates: [Double] {
        let maxMED = getMaxMED()
        let calendar = Calendar.current
        let today = Date()
        
        var weeklyRates: [Double] = []
        
        // 오늘을 제외한 최근 7일
        for i in 1...7 {
            if let pastDate = calendar.date(byAdding: .day, value: -i, to: today) {
                let progressRate = getUVProgressRate(for: pastDate, maxMED: maxMED)
                weeklyRates.append(progressRate)
            }
        }
        
        return weeklyRates
    }
    
    /// 특정 날짜의 UV 진행률 계산
    private func getUVProgressRate(for date: Date, maxMED: Double) -> Double {
        // SwiftData에서 해당 날짜의 DailyUVExpose 조회
        let descriptor = FetchDescriptor<DailyUVExpose>()
        
        do {
            let allDailyData = try modelContext.fetch(descriptor)
            let targetDaily = allDailyData.first { daily in
                Calendar.current.isDate(daily.date, inSameDayAs: date)
            }
            
            guard let dailyUV = targetDaily else { return 0.0 }
            
            let progressRate = dailyUV.totalUVDose / maxMED
            return min(max(progressRate, 0.0), 1.0)
            
        } catch {
            print("❌ [DashboardViewModel] Failed to fetch daily UV data: \(error)")
            return 0.0
        }
    }
    
    // MARK: - User Profile Access Methods
    
    /// 사용자 프로필 조회 (캐시 사용)
    func getUserProfile() -> UserProfile {
        if let cached = cachedUserProfile {
            return cached
        }
        
        let profile = getUserProfileUseCase().getUserProfile()
        cachedUserProfile = profile
        return profile
    }
    
    /// 사용자 최대 MED 값 조회
    func getMaxMED() -> Double {
        return getUserProfile().skinType.maxMED
    }
    
    /// 사용자 프로필 캐시 새로고침
    private func refreshUserProfileCache() {
        cachedUserProfile = nil // 캐시 무효화
        _ = getUserProfile() // 새로운 프로필 로드 및 캐시
        print("🔄 [DashboardViewModel] User profile cache refreshed")
    }
    
    // MARK: - SwiftData Observation Methods
    
    /// SwiftData 변경사항 감지 설정 (NotificationCenter 사용)
    private func setupSwiftDataObservation() {
        // SwiftData 변경사항을 NotificationCenter로 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSwiftDataUpdate),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }
    
    /// SwiftData 업데이트 처리
    @objc private func handleSwiftDataUpdate() {
        Task { @MainActor in
            do {
                let todayUVExposure = try await getTodayUVExposureUseCase().getTodayDailyUVExposure()
                
                if let todayData = todayUVExposure {
                    self.todayUVExposure = todayData
                    self.todayMEDValue = todayData.totalUVDose
                    self.todayTotalSunlightMinutes = Int(todayData.totalSunlightMinutes)
                    print("📊 [DashboardViewModel] SwiftData updated: \(String(format: "%.4f", todayData.totalUVDose)) J/m²")
                }
            } catch {
                print("❌ [DashboardViewModel] Failed to handle SwiftData update: \(error)")
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// 일출/일몰 시간으로 일광시간 계산
    private func calculateTotalSunlightMinutes() {
        guard let weather = currentWeather,
              let sunrise = weather.sunriseTime,
              let sunset = weather.sunsetTime else {
            todayTotalSunlightMinutes = 0
            return
        }
        
        let sunlightDuration = sunset.timeIntervalSince(sunrise)
        todayTotalSunlightMinutes = Int(sunlightDuration / 60) // 분 단위로 변환
    }
    
    /// 현재 날씨 정보 로그
    private func logCurrentWeatherInfo() {
        guard let weather = currentWeather else { return }
        print("📊 [DashboardViewModel] Weather loaded: \(weather.city), UV: \(currentUVIndex), Temp: \(currentTemperature)°C")
    }
    
    // MARK: - Notification Handlers
    
    /// 사용자 프로필 변경 시 호출되는 메서드
    @objc private func handleUserProfileUpdate(_ notification: Notification) {
        print("👤 [DashboardViewModel] User profile change detected")
        
        // 사용자 프로필 캐시 새로고침
        refreshUserProfileCache()
        
        // UI 업데이트를 위해 objectWillChange 발생
        objectWillChange.send()
        
        // 변경된 프로필 정보 로그
        let newProfile = getUserProfile()
        print("👤 [DashboardViewModel] Updated profile - Skin Type: \(newProfile.skinType.title), SPF: \(newProfile.spfLevel.displayTitle), Max MED: \(newProfile.skinType.maxMED)")
    }
    
    /// HealthKit 데이터 업데이트 시 호출되는 메서드
    @objc private func handleHealthKitUpdate() {
        let now = Date()
        print("🔄 [DashboardViewModel] HealthKit data change detected")
        
        // 중복 동기화 방지
        guard !isHealthKitSyncing else {
            print("⏸️ [DashboardViewModel] HealthKit sync already in progress - skipping")
            return
        }
        
        // 디바운싱: 마지막 동기화로부터 30초 이내면 스킵
        guard now.timeIntervalSince(lastHealthKitSyncTime) > 30 else {
            print("⏰ [DashboardViewModel] Too frequent HealthKit updates - debouncing (last sync: \(Int(now.timeIntervalSince(lastHealthKitSyncTime)))s ago)")
            return
        }
        
        isHealthKitSyncing = true
        
        Task { @MainActor in
            defer {
                isHealthKitSyncing = false
                lastHealthKitSyncTime = now
            }
            
            do {
                // 먼저 HealthKit 권한 확인
                let hasPermission = await HealthKitQueryFetchManager.shared.checkAuthorizationStatus()
                guard hasPermission else {
                    print("⚠️ [DashboardViewModel] HealthKit permission not granted - skipping sync")
                    return
                }
                
                // UV 데이터 새로고침
                try await syncUVDataFromHealthKitUseCase().syncTodaySunlightFromHealthKit()
                
                // 업데이트된 UV 노출량 조회
                let updatedUVExposure = try await getTodayUVExposureUseCase().getTodayDailyUVExposure()
                
                self.todayUVExposure = updatedUVExposure
                
                // HealthKit에서 가져온 실제 일광시간으로 업데이트
                let actualSunlightMinutes = getTodayUVExposureUseCase().getTotalSunlightMinutes(from: updatedUVExposure)
                self.todayTotalSunlightMinutes = Int(actualSunlightMinutes)
                
                // UV Dose 값 업데이트
                let newMEDValue = getTodayUVExposureUseCase().getTotalUVDose(from: updatedUVExposure)
                self.todayMEDValue = newMEDValue
                
                print("✅ [DashboardViewModel] UV data refreshed: \(self.todayTotalSunlightMinutes) minutes, \(String(format: "%.4f", self.todayMEDValue)) J/m²")
                
                // watch 로 데이터 보내기
                self.syncUVDataToWatch()
            } catch {
                // 타임아웃 에러는 조용히 처리
                if let healthKitError = error as? HealthKitError,
                   case .queryFailed(let underlyingError) = healthKitError,
                   underlyingError.localizedDescription.contains("timeout") {
                    print("⏰ [DashboardViewModel] HealthKit query timeout - likely no new data available")
                } else if error.localizedDescription.contains("timeout") {
                    print("⏰ [DashboardViewModel] HealthKit timeout - no new data to sync")
                } else {
                    print("❌ [DashboardViewModel] Failed to refresh UV data after HealthKit update: \(error)")
                    // 실제 에러는 사용자에게 표시하지 않음 (백그라운드 동기화이므로)
                }
            }
        }
    }
}

extension DashboardViewModel {
    
    /// Watch로 UV 데이터 전송 (개선된 버전)
    private func syncUVDataToWatch() {
        #if os(iOS)
        // 전송할 데이터가 모두 준비되었는지 확인
        guard let weather = currentWeather else {
            print("⚠️ [DashboardViewModel] Weather data not available - cannot sync to Watch")
            return
        }
        
        // UV 상태 레벨 계산
        let statusLevel = calculateUVStatusLevel()
        let progressRate = todayUVProgressRate
        
        print("📡 [DashboardViewModel] Preparing UV data for Watch:")
        print("   📊 MED Value: \(String(format: "%.4f", todayMEDValue)) J/m²")
        print("   ☀️ UV Index: \(currentUVIndex)")
        print("   🚦 Status Level: \(statusLevel)")
        print("   📍 Location: \(currentCityName)")
        print("   📈 Progress Rate: \(String(format: "%.1f", progressRate * 100))%")
        
        // SunscreenViewModel을 통해 Watch로 데이터 전송
        SunscreenViewModel.shared.sendUVDataToWatch(
            medValue: progressRate * 100, // 백분율로 변환
            uvIndex: currentUVIndex,
            statusLevel: statusLevel,
            location: currentCityName
        )
        
        // 연결 상태 확인 및 로그
        let manager = WatchConnectivityManager.shared
        
        if !manager.isPaired {
            print("❌ [DashboardViewModel] Watch not paired!")
        } else if !manager.isWatchAppInstalled {
            print("❌ [DashboardViewModel] Watch app not installed!")
        } else if !manager.isReachable {
            print("⚠️ [DashboardViewModel] Watch not reachable (background mode)")
        } else {
            print("✅ [DashboardViewModel] UV data successfully sent to Watch")
        }
        
        #endif
    }
    
    /// UV 상태 레벨 계산 (기존과 동일)
    private func calculateUVStatusLevel() -> String {
        let progressRate = todayUVProgressRate
        
        switch progressRate {
        case 0.0..<0.3:
            return "안전"
        case 0.3..<0.5:
            return "주의"
        case 0.5..<0.7:
            return "위험"
        default:
            return "매우위험"
        }
    }
    
    /// 수동으로 Watch 데이터 동기화 (디버깅용)
    func forceSyncToWatch() {
        #if os(iOS)
        print("🔄 [DashboardViewModel] Force syncing UV data to Watch...")
        syncUVDataToWatch()
        #endif
    }
    
    /// Watch에서 데이터 새로고침 요청 처리
    func handleWatchDataRefreshRequest() {
        print("🔄 [DashboardViewModel] Watch requested data refresh")
        
        Task { @MainActor in
            // 최신 데이터로 새로고침
            await refreshAllData()
            
            // Watch로 업데이트된 데이터 전송
            syncUVDataToWatch()
        }
    }
}

// MARK: - WatchConnectivity Message Handling

extension DashboardViewModel {
    
    /// WatchConnectivity 메시지 수신 설정
    func setupWatchConnectivityObservation() {
        #if os(iOS)
        // Watch에서 오는 메시지 처리
        WatchConnectivityManager.shared.messageFromWatchPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleWatchMessage(message)
            }
            .store(in: &cancellables)
        
        print("📡 [DashboardViewModel] WatchConnectivity observation setup completed")
        #endif
    }
    
    #if os(iOS)
    /// Watch에서 온 메시지 처리
    private func handleWatchMessage(_ message: [String: Any]) {
        print("📱 [DashboardViewModel] Received message from Watch: \(message)")
        
        if let action = message["action"] as? String {
            switch action {
            case "requestUVDataRefresh":
                handleWatchDataRefreshRequest()
            default:
                print("🤷‍♂️ [DashboardViewModel] Unknown action from Watch: \(action)")
            }
        }
    }
    #endif
}

// MARK: - Initialization Update

// DashboardViewModel의 init 메서드에 추가할 코드:
/*
init(modelContext: ModelContext) {
    self.modelContext = modelContext
    
    // ... 기존 코드 ...
    
    // ✅ WatchConnectivity 관찰 설정 추가
    setupWatchConnectivityObservation()
}
*/
