//
//  SyncWeatherDataUseCase.swift
//  TarTanning
//
//  Created by Jun on 7/26/25.
//

import Foundation
import SwiftData
import WeatherKit

enum WeatherSyncType {
    case syncAll                 // 전체 동기화 (위치와 날짜 모두 체크)
    case syncByLocationChange    // 위치 변경으로 인한 동기화
    case syncByDateChange        // 날짜 변경으로 인한 동기화
    case backgroundSync          // 백그라운드 동기화
}

@MainActor
final class SyncWeatherDataUseCase {
    private let weatherKitManager = WeatherKitManager.shared
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// 날씨 데이터 동기화
    func syncWeatherData(for locationInfo: LocationInfo, type: WeatherSyncType) async throws -> LocationWeather {
        print("🔄 [SyncWeatherDataUseCase] Executing \(type) for \(locationInfo.city)")
        
        switch type {
        case .syncByLocationChange:
            return try await syncByLocationChange(newLocation: locationInfo)
            
        case .syncByDateChange:
            return try await syncByDateChange(for: locationInfo)
            
        case .syncAll:
            return try await syncAll(for: locationInfo)
            
        case .backgroundSync:
            return try await backgroundSync(for: locationInfo)
        }
    }
    
    // MARK: - Private Sync Methods
    
    /// 위치 변경으로 인한 동기화
    private func syncByLocationChange(newLocation: LocationInfo) async throws -> LocationWeather {
        print("📍 [SyncWeatherDataUseCase] Location changed to \(newLocation.city)")
        
        // 1. 기존 데이터가 있는지 확인 후 삭제
        let fetchDescriptor = FetchDescriptor<LocationWeather>()
        let existingData = try modelContext.fetch(fetchDescriptor)
        
        if !existingData.isEmpty {
            try await clearAllData()
            print("🗑️ [SyncWeatherDataUseCase] Cleared existing data due to location change")
        } else {
            print("📭 [SyncWeatherDataUseCase] No existing data to clear")
        }
        
        // 2. 새 위치의 날씨 데이터 가져오기
        return try await fetchAndSaveWeatherData(for: newLocation)
    }
    
    /// 날짜 변경으로 인한 동기화
    private func syncByDateChange(for locationInfo: LocationInfo) async throws -> LocationWeather {
        print("📅 [SyncWeatherDataUseCase] Date changed, updating weather data")
        
        // 1. 기존 데이터가 있는지 확인 후 삭제
        let fetchDescriptor = FetchDescriptor<LocationWeather>()
        let existingData = try modelContext.fetch(fetchDescriptor)
        
        if !existingData.isEmpty {
            try await clearAllData()
            print("🗑️ [SyncWeatherDataUseCase] Cleared existing data due to date change")
        } else {
            print("📭 [SyncWeatherDataUseCase] No existing data to clear")
        }
        
        // 2. 오늘 날씨 데이터 가져오기
        return try await fetchAndSaveWeatherData(for: locationInfo)
    }
    
    /// 전체 동기화 (위치와 날짜 모두 체크)
    private func syncAll(for locationInfo: LocationInfo) async throws -> LocationWeather {
        print("🔄 [SyncWeatherDataUseCase] Full sync - checking location and date changes")
        
        let currentDate = Calendar.current.startOfDay(for: Date())
        let currentLocationId = "\(locationInfo.latitude),\(locationInfo.longitude)_\(currentDate.formatted(.iso8601.year().month().day()))"
        
        let fetchDescriptor = FetchDescriptor<LocationWeather>()
        let allData = try modelContext.fetch(fetchDescriptor)
        
        // 현재 위치와 날짜에 정확히 맞는 데이터가 있는지 확인
        let exactMatch = allData.first(where: { $0.id == currentLocationId })
        
        if let exactMatch = exactMatch {
            // 정확히 일치하는 데이터가 있으면 그대로 반환 (새로고침 케이스)
            print("✅ [SyncWeatherDataUseCase] Exact match found - using existing data (refresh case)")
            return exactMatch
        } else {
            // 일치하는 데이터가 없음
            if !allData.isEmpty {
                // 기존 데이터가 있으면 삭제 후 새로 생성
                print("🔄 [SyncWeatherDataUseCase] Clearing outdated data and creating new")
                try await clearAllData()
            } else {
                // 초기 상태 (데이터 없음)
                print("🆕 [SyncWeatherDataUseCase] Initial state - creating first data")
            }
            
            return try await fetchAndSaveWeatherData(for: locationInfo)
        }
    }
    
    /// 백그라운드 동기화
    private func backgroundSync(for locationInfo: LocationInfo) async throws -> LocationWeather {
        print("🌙 [SyncWeatherDataUseCase] Background sync")
        
        // 백그라운드에서는 기존 데이터 우선 사용
        let currentDate = Calendar.current.startOfDay(for: Date())
        let locationId = "\(locationInfo.latitude),\(locationInfo.longitude)_\(currentDate.formatted(.iso8601.year().month().day()))"
        
        let fetchDescriptor = FetchDescriptor<LocationWeather>()
        let allData = try modelContext.fetch(fetchDescriptor)
        
        let existingData = allData.first(where: { $0.id == locationId })
        
        if let existingData = existingData {
            print("✅ [SyncWeatherDataUseCase] Background sync - using existing data")
            return existingData
        } else {
            print("🔄 [SyncWeatherDataUseCase] Background sync - creating new data")
            try await clearAllData()
            return try await fetchAndSaveWeatherData(for: locationInfo)
        }
    }
    
    // MARK: - Helper Methods
    
    /// 모든 데이터 삭제
    func clearAllData() async throws {
        // 모든 HourlyWeather 삭제
        let hourlyDescriptor = FetchDescriptor<HourlyWeather>()
        let allHourlyData = try modelContext.fetch(hourlyDescriptor)
        for hourlyWeather in allHourlyData {
            modelContext.delete(hourlyWeather)
        }
        
        // 모든 LocationWeather 삭제
        let locationDescriptor = FetchDescriptor<LocationWeather>()
        let allLocationData = try modelContext.fetch(locationDescriptor)
        for locationWeather in allLocationData {
            modelContext.delete(locationWeather)
        }
        
        try modelContext.save()
        print("🗑️ [SyncWeatherDataUseCase] Cleared all weather data")
    }
    
    /// 날씨 데이터 가져오기 및 저장
    private func fetchAndSaveWeatherData(for locationInfo: LocationInfo) async throws -> LocationWeather {
        // 1. 먼저 동일한 위치/날짜의 기존 데이터가 있는지 확인하고 삭제
        let currentDate = Calendar.current.startOfDay(for: Date())
        let locationId = "\(locationInfo.latitude),\(locationInfo.longitude)_\(currentDate.formatted(.iso8601.year().month().day()))"
        
        let fetchDescriptor = FetchDescriptor<LocationWeather>()
        let allData = try modelContext.fetch(fetchDescriptor)
        
        // 동일한 ID의 기존 데이터 삭제
        let existingData = allData.filter { $0.id == locationId }
        for data in existingData {
            // HourlyWeather들을 먼저 삭제
            for hourlyWeather in data.hourlyWeathers {
                modelContext.delete(hourlyWeather)
            }
            modelContext.delete(data)
            print("🗑️ [SyncWeatherDataUseCase] Removed existing data with same ID: \(locationId)")
        }
        
        // 2. 새로운 데이터 가져오기
        let rawWeatherData = try await weatherKitManager.fetchRawWeatherData(for: locationInfo)
        
        let locationWeather = convertRawDataToEntity(
            rawData: rawWeatherData,
            locationInfo: locationInfo,
            targetDate: currentDate
        )
        
        // 3. 새 데이터 저장
        modelContext.insert(locationWeather)
        try modelContext.save()
        
        print("✅ [SyncWeatherDataUseCase] Successfully saved weather data for \(locationInfo.city)")
        return locationWeather
    }
    
    /// Raw 데이터를 Entity로 변환
    private func convertRawDataToEntity(rawData: Weather, locationInfo: LocationInfo, targetDate: Date) -> LocationWeather {
        // LocationWeather 생성
        let locationWeather = LocationWeather(
            date: targetDate,
            locationInfo: locationInfo,
            sunriseTime: rawData.dailyForecast.forecast.first?.sun.sunrise,
            sunsetTime: rawData.dailyForecast.forecast.first?.sun.sunset
        )
        
        // 0시부터 23시까지 모든 시간대의 데이터 필터링 (총 24개: 0,1,2...22,23)
        let filteredHourlyData = rawData.hourlyForecast.forecast
            .filter { hourlyForecast in
                let forecastDate = Calendar.current.startOfDay(for: hourlyForecast.date)
                let hour = Calendar.current.component(.hour, from: hourlyForecast.date)
                return forecastDate == targetDate && hour >= 0 && hour <= 23
            }
            .sorted { $0.date < $1.date } // 시간순으로 정렬
        
        print("📊 [SyncWeatherDataUseCase] Filtered hourly data count: \(filteredHourlyData.count)")
        
        // HourlyWeather 엔티티들을 안전하게 생성하고 관계 설정
        for hourlyForecast in filteredHourlyData {
            let hourlyWeather = HourlyWeather(
                date: hourlyForecast.date,
                uvIndex: Double(hourlyForecast.uvIndex.value),
                temperature: hourlyForecast.temperature.value
            )
            
            // 쓰레드 안전한 관계 설정
            hourlyWeather.locationWeather = locationWeather
            locationWeather.hourlyWeathers.append(hourlyWeather)
        }
        
        return locationWeather
    }
} 