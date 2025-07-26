//
//  DashboardViewModel.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var currentWeather: LocationWeather?
    @Published var todayTotalSunlightMinutes: Int = 0
    @Published var todayUVExposure: DailyUVExpose?
    @Published var todayMEDValue: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let modelContext: ModelContext
    // Weather UseCase들 (싱글톤 + 의존성 주입)
    private lazy var getWeatherDataUseCase = GetWeatherDataUseCase(modelContext: modelContext)
    private lazy var syncWeatherDataUseCase = SyncWeatherDataUseCase(modelContext: modelContext)
    
    // UV Exposure UseCase들 (싱글톤 + 의존성 주입)
    private lazy var syncUVDataFromHealthKitUseCase = SyncUVDataFromHealthKitUseCase(modelContext: modelContext)
    private lazy var getTodayUVExposureUseCase = GetTodayUVExposureUseCase(modelContext: modelContext)
    private lazy var calculateAndSaveUVDoseUseCase = CalculateAndSaveUVDoseUseCase(modelContext: modelContext)
    private lazy var getUserProfileUseCase = GetUserProfileUseCase()
    
    private var currentLocation = LocationInfo.mockSeoul
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Computed Properties
    var currentUVIndex: Double {
        guard let weather = currentWeather else { return 0.0 }
        return getWeatherDataUseCase.getCurrentUVIndex(from: weather)
    }
    
    var currentTemperature: Int {
        guard let weather = currentWeather else { return 0 }
        return Int(getWeatherDataUseCase.getCurrentTemperature(from: weather))
    }
    
    var currentCityName: String {
        return currentWeather?.city ?? currentLocation.city
    }
    
    // MARK: - UV Progress Calculation
    
    var todayUVProgressRate: Double {
        guard let dailyUV = todayUVExposure else { return 0.0 }
        
        // 사용자 프로필에서 maxMED 가져오기
        let userProfile = getUserProfileUseCase.getUserProfile()
        let maxMED = userProfile.skinType.maxMED
        
        // 현재 UV Dose를 maxMED로 나누어 진행률 계산
        let progressRate = dailyUV.totalUVDose / maxMED
        
        // 0.0 ~ 1.0 범위로 제한
        return min(max(progressRate, 0.0), 1.0)
    }
    
    // MARK: - Weather Methods
    
    func loadWeatherData() {
        isLoading = true
        errorMessage = nil
        
        print("🔄 [DashboardViewModel] Loading weather data for \(currentLocation.city)")
        
        Task { @MainActor in
            do {
                let weatherData = try await syncWeatherDataUseCase.syncWeatherData(
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
    
    func updateLocation(_ newLocation: LocationInfo) {
        print("📍 [DashboardViewModel] Location update to \(newLocation.city)")
        currentLocation = newLocation
        
        Task { @MainActor in
            do {
                let weatherData = try await syncWeatherDataUseCase.syncWeatherData(
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
    // MARK: - UV Exposure Methods
    
    func loadUVExposureData() {
        print("🔄 [DashboardViewModel] Loading UV exposure data")
        
        Task { @MainActor in
            do {
                // 1. HealthKit에서 일광시간 데이터 동기화
                try await syncUVDataFromHealthKitUseCase.syncTodaySunlightFromHealthKit()
                
                // 2. 오늘의 UV 노출량 조회
                let todayUVExposure = try await getTodayUVExposureUseCase.getTodayDailyUVExposure()
                
                self.todayUVExposure = todayUVExposure
                
                // HealthKit에서 가져온 실제 일광시간으로 업데이트
                let actualSunlightMinutes = getTodayUVExposureUseCase.getTotalSunlightMinutes(from: todayUVExposure)
                self.todayTotalSunlightMinutes = Int(actualSunlightMinutes)
                
                print("✅ [DashboardViewModel] UV exposure data loaded: \(self.todayTotalSunlightMinutes) minutes (from HealthKit)")
                
            } catch {
                self.errorMessage = "UV 노출량 데이터를 불러올 수 없습니다"
                print("❌ [DashboardViewModel] Failed to load UV exposure data: \(error)")
            }
        }
    }
    
    func calculateAndSaveUVDose() {
        print("🧮 [DashboardViewModel] Calculating and saving UV dose")
        
        guard let weather = currentWeather else {
            print("⚠️ [DashboardViewModel] No weather data available for UV dose calculation")
            return
        }
        
        Task { @MainActor in
            do {
                // UV 지수 데이터 준비 (시간별)
                var uvIndexData: [Int: Double] = [:]
                for hourlyWeather in weather.hourlyWeathers {
                    uvIndexData[hourlyWeather.hour] = hourlyWeather.uvIndex
                }
                
                // UV Dose 계산 및 저장
                try await calculateAndSaveUVDoseUseCase.calculateAndSaveTodayUVDose(uvIndexData: uvIndexData)
                
                // 업데이트된 UV 노출량 조회
                let updatedUVExposure = try await getTodayUVExposureUseCase.getTodayDailyUVExposure()
                
                self.todayUVExposure = updatedUVExposure
                self.todayMEDValue = getTodayUVExposureUseCase.getTotalUVDose(from: updatedUVExposure)
                print("✅ [DashboardViewModel] UV dose calculated: \(String(format: "%.2f", self.todayMEDValue))")
                
            } catch {
                self.errorMessage = "UV Dose 계산에 실패했습니다"
                print("❌ [DashboardViewModel] Failed to calculate UV dose: \(error)")
            }
        }
    }
    
    func loadAllDashboardData() {
        print("🔄 [DashboardViewModel] Loading all dashboard data")
        
        Task { @MainActor in
            // 1. 날씨 데이터 로드
            loadWeatherData()
            
            // 2. UV 노출량 데이터 로드
            loadUVExposureData()
            
            // 3. UV Dose 계산
            calculateAndSaveUVDose()
            
            // 4. 주간 데이터 업데이트 (UI 자동 갱신)
            print("📊 [DashboardViewModel] Weekly UV progress rates: \(self.weeklyUVProgressRates)")
            
            print("✅ [DashboardViewModel] All dashboard data loaded successfully")
        }
    }
    
    // MARK: - Debug Methods (for SwiftDataDebugView)
    
    func syncHealthKitDataForDebug() async throws {
        try await syncUVDataFromHealthKitUseCase.syncTodaySunlightFromHealthKit()
    }
    
    func calculateUVDoseForDebug() async throws {
        guard let weather = currentWeather else { return }
        
        var uvIndexData: [Int: Double] = [:]
        for hourlyWeather in weather.hourlyWeathers {
            uvIndexData[hourlyWeather.hour] = hourlyWeather.uvIndex
        }
        
        try await calculateAndSaveUVDoseUseCase.calculateAndSaveTodayUVDose(uvIndexData: uvIndexData)
    }
    
    // MARK: - Public Access Methods
    
    func getUserProfile() -> UserProfile {
        return getUserProfileUseCase.getUserProfile()
    }
    
    func getMaxMED() -> Double {
        return getUserProfile().skinType.maxMED
    }
    
    // MARK: - Weekly UV Progress Calculation
    
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
    
    // MARK: - Private Methods
    private func calculateTotalSunlightMinutes() {
        guard let weather = currentWeather,
              let sunrise = weather.sunriseTime,
              let sunset = weather.sunsetTime else {
            todayTotalSunlightMinutes = 0
            return
        }
        
        let sunlightDuration = sunset.timeIntervalSince(sunrise)
        todayTotalSunlightMinutes = Int(sunlightDuration / 60) // 분 단위로 변환
        
        print("☀️ [DashboardViewModel] Calculated sunlight: \(todayTotalSunlightMinutes) minutes")
    }
    
    private func logCurrentWeatherInfo() {
        guard let weather = currentWeather else { return }
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        print("📊 [DashboardViewModel] Current weather info:")
        print("   - City: \(weather.city)")
        print("   - Current hour: \(currentHour)")
        print("   - Current UV: \(currentUVIndex)")
        print("   - Current temperature: \(currentTemperature)°C")
        print("   - Total hourly data: \(weather.hourlyWeathers.count)")
        print("   - Sunlight minutes: \(todayTotalSunlightMinutes)")
    }
    
    // MARK: - Debug Methods
    func clearAllData() {
        Task {
            do {
                try await syncWeatherDataUseCase.clearAllData()
                
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
    
}
