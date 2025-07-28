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
                
            } catch {
                self.isLoading = false
                if let weatherError = error as? WeatherManagerError {
                    self.errorMessage = weatherError.localizedDescription
                } else {
                    self.errorMessage = "날씨 정보를 불러올 수 없습니다"
                }
                print("❌ [DashboardViewModel] Failed to load weather: \(error)")
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
        
        print("🔄 [DashboardViewModel] Loading weather data for \(currentLocation.city)")
        
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
            print("❌ [DashboardViewModel] Failed to load weather: \(error)")
        }
    }
    
    // MARK: - UV Exposure Feature Methods
    
    /// 기존 SwiftData에서 오늘의 UV 노출량 데이터를 직접 로드
    private func loadExistingUVData() {
        print("📊 [DashboardViewModel] Loading existing UV exposure data from SwiftData")
        
        Task { @MainActor in
            do {
                // 기존 SwiftData에서 오늘의 UV 노출량 조회
                let todayUVExposure = try await getTodayUVExposureUseCase().getTodayDailyUVExposure()
                
                if let todayData = todayUVExposure {
                    // 기존 데이터로 UI 업데이트
                    self.todayUVExposure = todayData
                    
                    let sunlightMinutes = getTodayUVExposureUseCase().getTotalSunlightMinutes(from: todayData)
                    self.todayTotalSunlightMinutes = Int(sunlightMinutes)
                    
                    let uvDose = getTodayUVExposureUseCase().getTotalUVDose(from: todayData)
                    self.todayMEDValue = uvDose
                    
                    print("✅ [DashboardViewModel] Existing UV data loaded: \(self.todayTotalSunlightMinutes) minutes, \(String(format: "%.4f", self.todayMEDValue)) J/m²")
                } else {
                    print("📭 [DashboardViewModel] No existing UV data found for today")
                    // 기본값으로 초기화
                    self.todayUVExposure = nil
                    self.todayTotalSunlightMinutes = 0
                    self.todayMEDValue = 0.0
                }
                
            } catch {
                print("❌ [DashboardViewModel] Failed to load existing UV data: \(error)")
                // 에러 시 기본값으로 초기화
                self.todayUVExposure = nil
                self.todayTotalSunlightMinutes = 0
                self.todayMEDValue = 0.0
            }
        }
    }
    
    /// UV 노출량 데이터 로드 (기존 데이터 우선 로드 후 HealthKit 동기화)
    func loadUVExposureData() {
        print("🔄 [DashboardViewModel] Loading UV exposure data")
        
        // 1. 먼저 기존 SwiftData에서 데이터 로드 (즉시 UI 업데이트)
        loadExistingUVData()
        
        // 2. 그 다음 HealthKit 동기화 (백그라운드에서 진행)
        syncAndUpdateUVDataFromHealthKit()
    }
    
    /// HealthKit 동기화 및 UV 데이터 업데이트 (백그라운드)
    private func syncAndUpdateUVDataFromHealthKit() {
        // 이미 동기화 중이면 스킵
        guard !isHealthKitSyncing else {
            print("⏸️ [DashboardViewModel] HealthKit sync already in progress - skipping syncAndUpdateUVDataFromHealthKit")
            return
        }
        
        print("🔄 [DashboardViewModel] Starting HealthKit sync and update")
        
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
                
                // 2. 동기화 후 업데이트된 UV 노출량 조회
                print("📱 [DashboardViewModel] Step 2: Fetching updated UV exposure...")
                let updatedUVExposure = try await getTodayUVExposureUseCase().getTodayDailyUVExposure()
                
                self.todayUVExposure = updatedUVExposure
                
                // HealthKit에서 가져온 실제 일광시간으로 업데이트
                let actualSunlightMinutes = getTodayUVExposureUseCase().getTotalSunlightMinutes(from: updatedUVExposure)
                self.todayTotalSunlightMinutes = Int(actualSunlightMinutes)
                
                // UV Dose 값 업데이트
                let newMEDValue = getTodayUVExposureUseCase().getTotalUVDose(from: updatedUVExposure)
                self.todayMEDValue = newMEDValue
                
                print("✅ [DashboardViewModel] UV exposure data updated after HealthKit sync: \(self.todayTotalSunlightMinutes) minutes, \(String(format: "%.4f", self.todayMEDValue)) J/m²")
                
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
    
    // MARK: - Debug Methods (for SwiftDataDebugView)
    
    /// HealthKit 데이터 동기화 (디버그용)
    func syncHealthKitDataForDebug() async throws {
        try await syncUVDataFromHealthKitUseCase().syncTodaySunlightFromHealthKit()
    }
    
    /// UV Dose 계산 (디버그용)
    func calculateUVDoseForDebug() async throws {
        // SwiftData에서 직접 UV 지수를 조회하여 계산
        try await calculateAndSaveUVDoseUseCase().calculateAndSaveTodayUVDose()
    }
    
    /// 모든 데이터 삭제 (디버그용)
    func clearAllData() {
        Task {
            do {
                try await syncWeatherDataUseCase().clearAllData()
                
                await MainActor.run {
                    self.currentWeather = nil
                    self.todayTotalSunlightMinutes = 0
                    print("🗑️ [DashboardViewModel] All data cleared")
                }
            } catch {
                print("❌ [DashboardViewModel] Failed to clear data: \(error)")
            }
        }
    }
    
    /// SwiftData 상세 상태 로그 (디버그용)
    func logDetailedSwiftDataStatus() {
        Task {
            do {
                print("📊 ===== SwiftData 상세 상태 =====")
                
                // LocationWeather 데이터
                let locationDescriptor = FetchDescriptor<LocationWeather>()
                let allLocationData = try modelContext.fetch(locationDescriptor)
                
                print("📍 LocationWeather 총 개수: \(allLocationData.count)")
                
                for (index, location) in allLocationData.enumerated() {
                    print("\n📍 LocationWeather[\(index)]:")
                    print("   • ID: \(location.id)")
                    print("   • 도시: \(location.city)")
                    print("   • 위도: \(location.latitude)")
                    print("   • 경도: \(location.longitude)")
                    print("   • 날짜: \(location.date.formatted(date: .abbreviated, time: .omitted))")
                    print("   • 일출: \(location.sunriseTime?.formatted(date: .omitted, time: .shortened) ?? "N/A")")
                    print("   • 일몰: \(location.sunsetTime?.formatted(date: .omitted, time: .shortened) ?? "N/A")")
                    print("   • 연결된 시간별 데이터: \(location.hourlyWeathers.count)개")
                }
                
                // HourlyWeather 데이터
                let hourlyDescriptor = FetchDescriptor<HourlyWeather>()
                let allHourlyData = try modelContext.fetch(hourlyDescriptor)
                
                print("\n🕐 HourlyWeather 총 개수: \(allHourlyData.count)")
                
                let sortedHourlyData = allHourlyData.sorted { $0.date < $1.date }
                
                for (index, hourly) in sortedHourlyData.enumerated() {
                    print("\n🕐 HourlyWeather[\(index)]:")
                    print("   • 시간: \(hourly.hour)시 (\(hourly.date.formatted(date: .omitted, time: .shortened)))")
                    print("   • 온도: \(hourly.temperature)°")
                    print("   • UV 지수: \(hourly.uvIndex)")
                    print("   • 연결된 위치: \(hourly.locationWeather?.city ?? "연결 안됨")")
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
