//
//  GetWeatherDataUseCase.swift
//  TarTanning
//
//  Created by Jun on 7/26/25.
//

import Foundation
import SwiftData

@MainActor
final class GetWeatherDataUseCase {
    private let weatherKitManager = WeatherKitManager.shared
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// 오늘 날씨 데이터 조회
    func getTodayWeatherData(for locationInfo: LocationInfo) async throws -> LocationWeather? {
        let currentDate = Calendar.current.startOfDay(for: Date())
        let locationId = "\(locationInfo.latitude),\(locationInfo.longitude)_\(currentDate.formatted(.iso8601.year().month().day()))"
        
        let fetchDescriptor = FetchDescriptor<LocationWeather>()
        let allData = try modelContext.fetch(fetchDescriptor)
        
        let weatherData = allData.first(where: { $0.id == locationId })
        
        if let weatherData = weatherData {
            print("📊 [GetWeatherDataUseCase] 오늘 날씨 데이터 발견: \(locationInfo.city)")
        } else {
            print("📭 [GetWeatherDataUseCase] 오늘 날씨 데이터 없음: \(locationInfo.city)")
        }
        
        return weatherData
    }
    
    /// 현재 시간의 UV 지수 추출
    func getCurrentUVIndex(from weather: LocationWeather?) -> Double {
        guard let weather = weather else { return 0.0 }
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        let currentHourWeather = weather.hourlyWeathers.first { $0.hour == currentHour }
        
        if let currentHourWeather = currentHourWeather {
            return currentHourWeather.uvIndex
        } else {
            // 가장 가까운 시간의 데이터 사용
            let sortedWeathers = weather.hourlyWeathers.sorted {
                abs($0.hour - currentHour) < abs($1.hour - currentHour)
            }
            return sortedWeathers.first?.uvIndex ?? 0.0
        }
    }
    
    /// 현재 시간의 온도 추출
    func getCurrentTemperature(from weather: LocationWeather?) -> Double {
        guard let weather = weather else { return 0.0 }
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        let currentHourWeather = weather.hourlyWeathers.first { $0.hour == currentHour }
        
        if let currentHourWeather = currentHourWeather {
            return currentHourWeather.temperature
        } else {
            // 가장 가까운 시간의 데이터 사용
            let sortedWeathers = weather.hourlyWeathers.sorted {
                abs($0.hour - currentHour) < abs($1.hour - currentHour)
            }
            return sortedWeathers.first?.temperature ?? 0.0
        }
    }
    
    /// 기존 데이터 불러오기
    func loadExistingData(for locationInfo: LocationInfo) async throws -> LocationWeather {
        let currentDate = Calendar.current.startOfDay(for: Date())
        let locationId = "\(locationInfo.latitude),\(locationInfo.longitude)_\(currentDate.formatted(.iso8601.year().month().day()))"
        
        let fetchDescriptor = FetchDescriptor<LocationWeather>()
        let allData = try modelContext.fetch(fetchDescriptor)
        
        guard let existingData = allData.first(where: { $0.id == locationId }) else {
            print("📭 [GetWeatherDataUseCase] No existing data found for current location and date")
            throw WeatherManagerError.weatherDataFetchFailed
        }
        
        print("✅ [GetWeatherDataUseCase] Found existing weather data")
        return existingData
    }
} 