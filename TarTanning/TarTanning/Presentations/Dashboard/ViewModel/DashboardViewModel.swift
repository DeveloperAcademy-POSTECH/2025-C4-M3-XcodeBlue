//
//  DashboardViewModel.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

// swiftlint:disable file_length type_body_length

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
    private func getWeatherDataUseCase() -> GetWeatherDataUseCase {
        return GetWeatherDataUseCase(modelContext: modelContext)
    }
    
    private func syncWeatherDataUseCase() -> SyncWeatherDataUseCase {
        return SyncWeatherDataUseCase(modelContext: modelContext)
    }
    
    private func syncUVDataFromHealthKitUseCase() -> SyncUVDataFromHealthKitUseCase {
        return SyncUVDataFromHealthKitUseCase(modelContext: modelContext)
    }
    
    private func getTodayUVExposureUseCase() -> GetTodayUVExposureUseCase {
        return GetTodayUVExposureUseCase(modelContext: modelContext)
    }
    
    private func calculateAndSaveUVDoseUseCase() -> CalculateAndSaveUVDoseUseCase {
        return CalculateAndSaveUVDoseUseCase(modelContext: modelContext)
    }
    
    private func getUserProfileUseCase() -> GetUserProfileUseCase {
        return GetUserProfileUseCase()
    }
    
    // MARK: - Private Properties
    private var currentLocation = LocationInfo.mockPohang
    private var cancellables = Set<AnyCancellable>()
    private var isHealthKitSyncing = false
    private var lastHealthKitSyncTime: Date = Date.distantPast
    
    // 캐시된 사용자 프로필 (중복 호출 방지)
    private var cachedUserProfile: UserProfile?
    
    // WatchConnectivity 관련 private properties
    private var lastWatchSyncTime: Date = Date.distantPast
    private let watchSyncDebounceInterval: TimeInterval = 1.0
    
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
        
        // ✨ WatchConnectivity 메시지 수신 설정
        #if os(iOS)
        setupWatchConnectivityMessageHandling()
        
        // Watch 연결 상태 감지 후 초기 데이터 전송
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
            print("test \(self.currentUVIndex)" )
            print("test \(self.currentCityName)" )
            self.sendDashboardDataToWatch()
        }
        #endif
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
    
    // MARK: - WatchConnectivity Integration
    #if os(iOS)
    private func setupWatchConnectivityMessageHandling() {
        WatchConnectivityManager.shared.messageFromWatchPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleWatchMessage(message)
            }
            .store(in: &cancellables)
        
        print("📱 [DashboardViewModel] Watch message handling setup completed")
    }
    
    private func handleWatchMessage(_ message: [String: Any]) {
        // 대시보드 데이터 동기화 요청 처리
        if message["request_dashboard_sync"] as? Bool == true {
            print("📱 [DashboardViewModel] Received dashboard sync request from Watch")
            sendDashboardDataToWatch()
            return
        }
        
        // 기타 메시지 처리 (필요 시 확장)
        print("📱 [DashboardViewModel] Received unhandled message from Watch: \(message)")
    }
    
    private func sendDashboardDataToWatch() {
        // 디바운싱으로 과도한 전송 방지
        let now = Date()
        guard now.timeIntervalSince(lastWatchSyncTime) >= watchSyncDebounceInterval else {
            print("📱 [DashboardViewModel] Watch sync debounced - too frequent")
            return
        }
        lastWatchSyncTime = now
        
        let dashboardData: [String: Any] = [
            "dashboard_currentCityName": self.currentCityName,
            "dashboard_currentUVIndex": self.currentUVIndex,
            "dashboard_todayUVProgressRate": self.todayUVProgressRate,
            "dashboard_totalSunlightMinutes": self.todayUVExposure?.totalSunlightMinutes ?? 0,
            "dashboard_totalUVDose": self.todayUVExposure?.totalUVDose ?? 0.0,
            "dashboard_lastUpdated": Date().timeIntervalSince1970
        ]
        
        WatchConnectivityManager.shared.sendContext(dashboardData)
    }
    #endif
    
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
                
                // ✨ 날씨 데이터 로드 완료 시 Watch로 전송
                #if os(iOS)
                sendDashboardDataToWatch()
                #endif
                
            } catch {
                self.isLoading = false
                if let weatherError = error as? WeatherManagerError {
                    switch weatherError {
                    case .locationUnavailable:
                        self.errorMessage = "위치 정보를 사용할 수 없습니다"
                    case .weatherDataFetchFailed:
                        self.errorMessage = "날씨 데이터를 불러올 수 없습니다"
                    case .noLocationPermission:
                        self.errorMessage = "위치 권한이 필요합니다"
                    default:
                        self.errorMessage = "날씨 데이터 로드 실패"
                    }
                } else {
                    self.errorMessage = "날씨 데이터를 불러올 수 없습니다"
                }
                
                print("❌ [DashboardViewModel] Failed to load weather data: \(error)")
            }
        }
    }
    
    /// 비동기 날씨 데이터 로드 (async/await 버전)
    @MainActor func loadWeatherDataAsync() async {
        isLoading = true
        errorMessage = nil
        
        print("🔄 [DashboardViewModel] Loading weather data async for \(currentLocation.city)")
        
        do {
            let weatherData = try await syncWeatherDataUseCase().syncWeatherData(
                for: currentLocation,
                type: .syncAll
            )
            
            self.currentWeather = weatherData
            self.isLoading = false
            self.logCurrentWeatherInfo()
            
            // ✨ 날씨 데이터 로드 완료 시 Watch로 전송
            #if os(iOS)
            sendDashboardDataToWatch()
            #endif
            
        } catch {
            self.isLoading = false
            if let weatherError = error as? WeatherManagerError {
                switch weatherError {
                case .locationUnavailable:
                    self.errorMessage = "위치 정보를 사용할 수 없습니다"
                case .weatherDataFetchFailed:
                    self.errorMessage = "날씨 데이터를 불러올 수 없습니다"
                case .noLocationPermission:
                    self.errorMessage = "위치 권한이 필요합니다"
                default:
                    self.errorMessage = "날씨 데이터 로드 실패"
                }
            } else {
                self.errorMessage = "날씨 데이터를 불러올 수 없습니다"
            }
            
            print("❌ [DashboardViewModel] Failed to load weather data async: \(error)")
        }
    }
    
    // MARK: - UV Exposure Feature Methods
    
    /// UV 노출량 데이터 로드
    func loadUVExposureData() {
        print("🔄 [DashboardViewModel] Loading UV exposure data")
        
        Task { @MainActor in
            do {
                // 1. HealthKit에서 일광 시간 데이터 동기화
                try await syncUVDataFromHealthKitUseCase().syncTodaySunlightFromHealthKit()
                print("✅ [DashboardViewModel] HealthKit sync completed")
                
                // 2. UV Dose 계산 및 저장 (SwiftData에서 실제 UV 지수 사용)
                try await calculateAndSaveUVDoseUseCase().calculateAndSaveTodayUVDose()
                print("✅ [DashboardViewModel] UV dose calculation completed")
                
                // 3. 오늘의 UV 노출량 조회
                let todayUVExposure = try await getTodayUVExposureUseCase().getTodayDailyUVExposure()
                
                self.todayUVExposure = todayUVExposure
                self.todayMEDValue = getTodayUVExposureUseCase().getTotalUVDose(from: todayUVExposure)
                self.todayTotalSunlightMinutes = Int(getTodayUVExposureUseCase().getTotalSunlightMinutes(from: todayUVExposure))
                
                print("📊 [DashboardViewModel] UV exposure data loaded:")
                print("   • Total UV Dose: \(String(format: "%.2f", self.todayMEDValue)) J/m²")
                print("   • Total Sunlight: \(self.todayTotalSunlightMinutes) minutes")
                print("   • Progress Rate: \(String(format: "%.1f", self.todayUVProgressRate * 100))%")
                
                // ✨ UV 데이터 로드 완료 시 Watch로 전송
                #if os(iOS)
                sendDashboardDataToWatch()
                #endif
                
            } catch {
                // 타임아웃 에러 처리
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
                    
                    print("❌ [DashboardViewModel] Failed to load UV exposure data: \(error)")
                }
            }
        }
    }
    
    /// UV Dose 재계산 (기존 데이터에 대한 UV Dose 업데이트)
    func recalculateUVDose() {
        print("🧮 [DashboardViewModel] Recalculating UV dose from SwiftData")
        
        Task { @MainActor in
            do {
                // UV Dose 재계산 및 저장 (SwiftData에서 직접 UV 지수 조회)
                try await calculateAndSaveUVDoseUseCase().calculateAndSaveTodayUVDose()
                
                // 업데이트된 UV 노출량 조회
                let updatedUVExposure = try await getTodayUVExposureUseCase().getTodayDailyUVExposure()
                
                self.todayUVExposure = updatedUVExposure
                self.todayMEDValue = getTodayUVExposureUseCase().getTotalUVDose(from: updatedUVExposure)
                print("✅ [DashboardViewModel] UV dose recalculated: \(String(format: "%.2f", self.todayMEDValue))")
                
                // ✨ UV Dose 재계산 완료 시 Watch로 전송
                #if os(iOS)
                sendDashboardDataToWatch()
                #endif
                
            } catch {
                self.errorMessage = "UV Dose 재계산에 실패했습니다"
                print("❌ [DashboardViewModel] Failed to recalculate UV dose: \(error)")
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
        
        // 2. UV 노출량 데이터 새로고침 (기존 데이터 로드 + HealthKit 동기화)
        loadUVExposureData()
        
        // ✨ 새로고침 완료 후 Watch로 데이터 전송
        #if os(iOS)
        sendDashboardDataToWatch()
        #endif
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
            print("❌ [DashboardViewModel] Failed to fetch UV progress for \(date): \(error)")
            return 0.0
        }
    }
    
    // MARK: - User Profile Helper Methods
    
    /// 사용자 프로필 가져오기 (캐시 활용)
    private func getUserProfile() -> UserProfile {
        if let cached = cachedUserProfile {
            return cached
        }
        
        let profile = getUserProfileUseCase().getUserProfile()
        cachedUserProfile = profile
        return profile
    }
    
    /// 사용자 프로필 캐시 새로고침
    private func refreshUserProfileCache() {
        cachedUserProfile = nil
        _ = getUserProfile() // 새로 로드하여 캐시 갱신
    }
    
    /// 사용자의 최대 MED 값 가져오기
    func getMaxMED() -> Double {
        return getUserProfile().skinType.maxMED
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
                    
                    // ✨ SwiftData 업데이트 시 Watch로 데이터 전송
                    #if os(iOS)
                    sendDashboardDataToWatch()
                    #endif
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
        
        // ✨ 프로필 변경 시 Watch로 업데이트된 데이터 전송
        #if os(iOS)
        sendDashboardDataToWatch()
        #endif
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
        
        // 디바운싱: 마지막 동기화로부터 최소 10초 간격 유지
        let debounceInterval: TimeInterval = 10.0
        guard now.timeIntervalSince(lastHealthKitSyncTime) >= debounceInterval else {
            print("⏸️ [DashboardViewModel] HealthKit sync debounced - too frequent")
            return
        }
        
        isHealthKitSyncing = true
        lastHealthKitSyncTime = now
        
        Task { @MainActor in
            defer {
                self.isHealthKitSyncing = false
            }
            
            do {
                print("🔄 [DashboardViewModel] Starting background HealthKit UV sync")
                
                // 1. HealthKit에서 일광 시간 데이터 동기화
                try await syncUVDataFromHealthKitUseCase().syncTodaySunlightFromHealthKit()
                print("✅ [DashboardViewModel] Background HealthKit sync completed")
                
                // 2. UV Dose 계산 및 저장
                try await calculateAndSaveUVDoseUseCase().calculateAndSaveTodayUVDose()
                print("✅ [DashboardViewModel] Background UV dose calculation completed")
                
                // 3. 업데이트된 데이터 UI에 반영
                let updatedUVExposure = try await getTodayUVExposureUseCase().getTodayDailyUVExposure()
                
                self.todayUVExposure = updatedUVExposure
                self.todayMEDValue = getTodayUVExposureUseCase().getTotalUVDose(from: updatedUVExposure)
                self.todayTotalSunlightMinutes = Int(getTodayUVExposureUseCase().getTotalSunlightMinutes(from: updatedUVExposure))
                
                print("📊 [DashboardViewModel] Background sync completed - UV Dose: \(String(format: "%.4f", self.todayMEDValue)) J/m²")
                
                // ✨ HealthKit 업데이트 완료 시 Watch로 데이터 전송
                #if os(iOS)
                sendDashboardDataToWatch()
                #endif
                
            } catch {
                print("❌ [DashboardViewModel] Background HealthKit sync failed: \(error)")
            }
        }
    }
    
    // MARK: - Debug & Utility Methods
    
    /// 상세 SwiftData 상태 로그 출력
    func logDetailedSwiftDataStatus() {
        Task { @MainActor in
            do {
                let locationDescriptor = FetchDescriptor<LocationWeather>()
                let hourlyDescriptor = FetchDescriptor<HourlyWeather>()
                let dailyDescriptor = FetchDescriptor<DailyUVExpose>()
                let recordDescriptor = FetchDescriptor<UVExposeRecord>()
                
                let allLocationData = try modelContext.fetch(locationDescriptor)
                let allHourlyData = try modelContext.fetch(hourlyDescriptor)
                let allDailyData = try modelContext.fetch(dailyDescriptor)
                let allRecordData = try modelContext.fetch(recordDescriptor)
                
                print("\n📊 [DashboardViewModel] 상세 SwiftData 상태:")
                print("==========================================")
                print("🌍 LocationWeather: \(allLocationData.count)개")
                print("⏰ HourlyWeather: \(allHourlyData.count)개")
                print("📅 DailyUVExpose: \(allDailyData.count)개")
                print("📝 UVExposeRecord: \(allRecordData.count)개")
                
                // 현재 날씨 상태
                if let current = currentWeather {
                    print("\n🌤️ 현재 날씨:")
                    print("   • 도시: \(current.city)")
                    print("   • 날짜: \(current.date.formatted(date: .abbreviated, time: .omitted))")
                    print("   • 시간별 데이터: \(current.hourlyWeathers.count)개")
                    print("   • 연결 상태: \(WatchConnectivityManager.shared.isReachable ? "연결됨" : "연결 안됨")")
                }
                
                // 관계 검증
                print("\n🔗 관계 검증:")
                for location in allLocationData {
                    let orphanedHourly = allHourlyData.filter { $0.locationWeather?.id != location.id }
                    if !orphanedHourly.isEmpty {
                        print("⚠️ 고아 HourlyWeather 발견: \(orphanedHourly.count)개")
                    }
                    
                    let duplicateHours = Dictionary(grouping: location.hourlyWeathers, by: { $0.hour })
                        .filter { $0.value.count > 1 }
                    if !duplicateHours.isEmpty {
                        print("⚠️ 중복 시간 발견: \(duplicateHours.keys.sorted())")
                    }
                }
                
                print("\n✅ SwiftData 상태 확인 완료")
                
            } catch {
                print("❌ SwiftData 상태 확인 실패: \(error)")
            }
        }
    }
    
    /// 모든 SwiftData 삭제 (디버깅용)
    func clearAllData() {
        Task { @MainActor in
            do {
                // 모든 데이터 타입 삭제
                try modelContext.delete(model: LocationWeather.self)
                try modelContext.delete(model: HourlyWeather.self)
                try modelContext.delete(model: DailyUVExpose.self)
                try modelContext.delete(model: UVExposeRecord.self)
                
                try modelContext.save()
                
                // 로컬 상태 초기화
                self.currentWeather = nil
                self.todayUVExposure = nil
                self.todayMEDValue = 0.0
                self.todayTotalSunlightMinutes = 0
                
                print("🗑️ [DashboardViewModel] All SwiftData cleared")
                
                // ✨ 데이터 초기화 후 Watch로 초기 상태 전송
                #if os(iOS)
                sendDashboardDataToWatch()
                #endif
                
            } catch {
                print("❌ [DashboardViewModel] Failed to clear data: \(error)")
            }
        }
    }
    
    /// UV Dose 계산 디버깅 (Development Only)
    func calculateUVDoseForDebug() async throws {
        print("🧮 [DashboardViewModel] Debug UV dose calculation started")
        
        // 1. 날씨 데이터 동기화
        let _ = try await syncWeatherDataUseCase().syncWeatherData(
            for: currentLocation,
            type: .syncAll
        )
        print("✅ Debug: Weather data synced")
        
        // 2. HealthKit 동기화
        try await syncUVDataFromHealthKitUseCase().syncTodaySunlightFromHealthKit()
        print("✅ Debug: HealthKit data synced")
        
        // 3. UV Dose 계산
        try await calculateAndSaveUVDoseUseCase().calculateAndSaveTodayUVDose()
        print("✅ Debug: UV dose calculated")
        
        // 4. 결과 업데이트
        let updatedData = try await getTodayUVExposureUseCase().getTodayDailyUVExposure()
        self.todayUVExposure = updatedData
        self.todayMEDValue = getTodayUVExposureUseCase().getTotalUVDose(from: updatedData)
        
        print("🎉 Debug: UV dose calculation completed - \(String(format: "%.4f", todayMEDValue)) J/m²")
        
        // ✨ 디버그 계산 완료 후 Watch로 데이터 전송
        #if os(iOS)
        sendDashboardDataToWatch()
        #endif
    }
    
    /// 현재 대시보드 상태 로그 출력 (디버깅용)
    func logCurrentDashboardState() {
        print("📊 [DashboardViewModel] Current Dashboard State:")
        print("   • City: \(currentCityName)")
        print("   • UV Index: \(String(format: "%.2f", currentUVIndex))")
        print("   • UV Progress: \(String(format: "%.1f", todayUVProgressRate * 100))%")
        print("   • MED Value: \(String(format: "%.4f", todayMEDValue)) J/m²")
        print("   • Temperature: \(currentTemperature)°C")
        print("   • Loading: \(isLoading)")
        print("   • Error: \(errorMessage ?? "None")")
        
        #if os(iOS)
        print("   • Watch Connection: \(WatchConnectivityManager.shared.isReachable ? "Connected" : "Disconnected")")
        #endif
    }
}
