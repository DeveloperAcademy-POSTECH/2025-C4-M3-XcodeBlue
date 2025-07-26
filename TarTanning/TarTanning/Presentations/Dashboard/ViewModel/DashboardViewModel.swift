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
    @Published var todayUVProgressRate: Double = 0.0
    @Published var weeklyUVProgressRates: [Double] = []
    @Published var currentWeather: LocationWeather?
    @Published var userProfile: UserProfile?
    @Published var todayTotalSunlightMinutes: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let modelContext: ModelContext
    private lazy var weatherSyncUseCase = WeatherSyncUseCase(
        weatherKitManager: WeatherKitManager.shared,
        modelContext: modelContext
    )
    private var currentLocation = LocationInfo.mockSeoul
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Computed Properties
    var currentUVIndex: Double {
        guard let weather = currentWeather else { return 0.0 }
        
        // 현재 시간에 해당하는 UV 지수 찾기
        let currentHour = Calendar.current.component(.hour, from: Date())
        let currentHourWeather = weather.hourlyWeathers.first { $0.hour == currentHour }
        
        if let currentHourWeather = currentHourWeather {
            return currentHourWeather.uvIndex
        } else {
            // 현재 시간 데이터가 없으면 가장 가까운 시간의 데이터 사용
            let sortedWeathers = weather.hourlyWeathers.sorted { abs($0.hour - currentHour) < abs($1.hour - currentHour) }
            return sortedWeathers.first?.uvIndex ?? 0.0
        }
    }
    
    var currentTemperature: Int {
        guard let weather = currentWeather else { return 0 }
        
        // 현재 시간에 해당하는 온도 찾기
        let currentHour = Calendar.current.component(.hour, from: Date())
        let currentHourWeather = weather.hourlyWeathers.first { $0.hour == currentHour }
        
        if let currentHourWeather = currentHourWeather {
            return Int(currentHourWeather.temperature)
        } else {
            // 현재 시간 데이터가 없으면 가장 가까운 시간의 데이터 사용
            let sortedWeathers = weather.hourlyWeathers.sorted { abs($0.hour - currentHour) < abs($1.hour - currentHour) }
            return Int(sortedWeathers.first?.temperature ?? 0)
        }
    }
    
    var currentCityName: String {
        return currentWeather?.city ?? currentLocation.city
    }
    
    // MARK: - Weather Methods
    
    func loadWeatherData() {
        isLoading = true
        errorMessage = nil
        
        print("🔄 [DashboardViewModel] Loading weather data for \(currentLocation.city)")
        
        Task {
            do {
                let weatherData = try await weatherSyncUseCase.execute(
                    for: currentLocation,
                    type: .syncAll
                )
                
                await MainActor.run {
                    self.currentWeather = weatherData
                    self.isLoading = false
                    self.calculateTotalSunlightMinutes()
                    self.logCurrentWeatherInfo()
                }
                
            } catch {
                await MainActor.run {
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
    }
    
    func updateLocation(_ newLocation: LocationInfo) {
        print("📍 [DashboardViewModel] Location update to \(newLocation.city)")
        currentLocation = newLocation
        
        Task {
            do {
                let weatherData = try await weatherSyncUseCase.execute(
                    for: newLocation,
                    type: .syncByLocationChange
                )
                
                await MainActor.run {
                    self.currentWeather = weatherData
                    self.calculateTotalSunlightMinutes()
                }
            } catch {
                await MainActor.run {
                    if let weatherError = error as? WeatherManagerError {
                        self.errorMessage = weatherError.localizedDescription
                    }
                }
            }
        }
    }
    
    func refreshWeatherData() {
        print("🔄 [DashboardViewModel] Refreshing weather data")
        loadWeatherData()
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
    func logSwiftDataStatus() {
        Task {
            do {
                let locationDescriptor = FetchDescriptor<LocationWeather>()
                let allLocationData = try modelContext.fetch(locationDescriptor)
                
                let hourlyDescriptor = FetchDescriptor<HourlyWeather>()
                let allHourlyData = try modelContext.fetch(hourlyDescriptor)
                
                await MainActor.run {
                    print("📊 [DashboardViewModel] SwiftData Status:")
                    print("   - LocationWeather count: \(allLocationData.count)")
                    print("   - HourlyWeather count: \(allHourlyData.count)")
                    
                    for location in allLocationData {
                        print("   - Location: \(location.city) (\(location.date))")
                        print("     - Hourly data: \(location.hourlyWeathers.count)")
                        
                        let sortedHours = location.hourlyWeathers.sorted { $0.hour < $1.hour }
                        if !sortedHours.isEmpty {
                            print("     - Hour range: \(sortedHours.first!.hour) - \(sortedHours.last!.hour)")
                        }
                    }
                }
            } catch {
                print("❌ [DashboardViewModel] Failed to fetch SwiftData: \(error)")
            }
        }
    }
    
    func clearAllData() {
        Task {
            do {
                // HourlyWeather 삭제
                let hourlyDescriptor = FetchDescriptor<HourlyWeather>()
                let allHourlyData = try modelContext.fetch(hourlyDescriptor)
                for hourlyWeather in allHourlyData {
                    modelContext.delete(hourlyWeather)
                }
                
                // LocationWeather 삭제
                let locationDescriptor = FetchDescriptor<LocationWeather>()
                let allLocationData = try modelContext.fetch(locationDescriptor)
                for locationWeather in allLocationData {
                    modelContext.delete(locationWeather)
                }
                
                try modelContext.save()
                
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
