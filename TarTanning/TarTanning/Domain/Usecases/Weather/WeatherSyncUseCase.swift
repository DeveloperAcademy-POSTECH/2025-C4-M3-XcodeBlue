//
//  WeatherSyncUseCase.swift
//  TarTanning
//
//  Created by Jun on 7/26/25.
//

import Foundation
import SwiftData
import WeatherKit

enum WeatherSyncType {
    case loadExistingData        // 기존 데이터 불러오기
    case syncByLocationChange    // 위치 변경으로 인한 동기화
    case syncByDateChange        // 날짜 변경으로 인한 동기화
    case syncAll                 // 전체 동기화 (위치와 날짜 모두 체크)
    case backgroundSync          // 백그라운드 동기화
}

final class WeatherSyncUseCase {
    private let weatherKitManager: WeatherKitManager
    private let modelContext: ModelContext
    
    init(weatherKitManager: WeatherKitManager, modelContext: ModelContext) {
        self.weatherKitManager = weatherKitManager
        self.modelContext = modelContext
    }
    
    func execute(for locationInfo: LocationInfo, type: WeatherSyncType) async throws -> LocationWeather {
        print("🔄 [WeatherSyncUseCase] Executing \(type) for \(locationInfo.city)")
        
        switch type {
        case .loadExistingData:
            return try await loadExistingData(for: locationInfo)
            
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
    
    // MARK: - 기존 데이터 불러오기
    private func loadExistingData(for locationInfo: LocationInfo) async throws -> LocationWeather {
        let currentDate = Calendar.current.startOfDay(for: Date())
        let locationId = "\(locationInfo.latitude),\(locationInfo.longitude)_\(currentDate.formatted(.iso8601.year().month().day()))"
        
        let fetchDescriptor = FetchDescriptor<LocationWeather>()
        let allData = try modelContext.fetch(fetchDescriptor)
        
        guard let existingData = allData.first(where: { $0.id == locationId }) else {
            print("📭 [WeatherSyncUseCase] No existing data found for current location and date")
            throw WeatherManagerError.weatherDataFetchFailed
        }
        
        print("✅ [WeatherSyncUseCase] Found existing weather data")
        return existingData
    }
    
    // MARK: - 위치 변경으로 인한 동기화
    private func syncByLocationChange(newLocation: LocationInfo) async throws -> LocationWeather {
        print("📍 [WeatherSyncUseCase] Location changed to \(newLocation.city)")
        
        // 1. 모든 기존 데이터 삭제 (위치가 바뀌었으므로)
        try await clearAllData()
        
        // 2. 새 위치의 날씨 데이터 가져오기
        return try await fetchAndSaveWeatherData(for: newLocation)
    }
    
    // MARK: - 날짜 변경으로 인한 동기화
    private func syncByDateChange(for locationInfo: LocationInfo) async throws -> LocationWeather {
        print("📅 [WeatherSyncUseCase] Date changed, updating weather data")
        
        // 1. 모든 기존 데이터 삭제 (날짜가 바뀌었으므로)
        try await clearAllData()
        
        // 2. 오늘 날씨 데이터 가져오기
        return try await fetchAndSaveWeatherData(for: locationInfo)
    }
    
    // MARK: - 전체 동기화 (위치와 날짜 모두 체크)
    private func syncAll(for locationInfo: LocationInfo) async throws -> LocationWeather {
        print("🔄 [WeatherSyncUseCase] Full sync - checking location and date changes")
        
        let currentDate = Calendar.current.startOfDay(for: Date())
        let currentLocationId = "\(locationInfo.latitude),\(locationInfo.longitude)_\(currentDate.formatted(.iso8601.year().month().day()))"
        
        let fetchDescriptor = FetchDescriptor<LocationWeather>()
        let allData = try modelContext.fetch(fetchDescriptor)
        
        // 현재 위치와 날짜에 정확히 맞는 데이터가 있는지 확인
        let exactMatch = allData.first(where: { $0.id == currentLocationId })
        
        if let exactMatch = exactMatch {
            // 정확히 일치하는 데이터가 있으면 그대로 반환 (새로고침 케이스)
            print("✅ [WeatherSyncUseCase] Exact match found - using existing data (refresh case)")
            return exactMatch
        } else {
            // 일치하는 데이터가 없으면 모든 기존 데이터 삭제 후 새로 생성
            print("🔄 [WeatherSyncUseCase] No exact match - clearing all data and creating new")
            try await clearAllData()
            return try await fetchAndSaveWeatherData(for: locationInfo)
        }
    }
    
    // MARK: - 백그라운드 동기화
    private func backgroundSync(for locationInfo: LocationInfo) async throws -> LocationWeather {
        print("🌙 [WeatherSyncUseCase] Background sync")
        
        // 백그라운드에서는 기존 데이터 우선 사용
        let currentDate = Calendar.current.startOfDay(for: Date())
        let locationId = "\(locationInfo.latitude),\(locationInfo.longitude)_\(currentDate.formatted(.iso8601.year().month().day()))"
        
        let fetchDescriptor = FetchDescriptor<LocationWeather>()
        let allData = try modelContext.fetch(fetchDescriptor)
        
        let existingData = allData.first(where: { $0.id == locationId })
        
        if let existingData = existingData {
            print("✅ [WeatherSyncUseCase] Background sync - using existing data")
            return existingData
        } else {
            print("🔄 [WeatherSyncUseCase] Background sync - creating new data")
            try await clearAllData()
            return try await fetchAndSaveWeatherData(for: locationInfo)
        }
    }
    
    // MARK: - Helper Methods
    private func clearAllData() async throws {
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
        print("🗑️ [WeatherSyncUseCase] Cleared all weather data")
    }
    
    private func clearOtherLocationData(newLocation: LocationInfo) async throws {
        let fetchDescriptor = FetchDescriptor<LocationWeather>()
        let allData = try modelContext.fetch(fetchDescriptor)
        
        let dataToDelete = allData.filter { data in
            data.latitude != newLocation.latitude || data.longitude != newLocation.longitude
        }
        
        for data in dataToDelete {
            // HourlyWeather들을 먼저 명시적으로 삭제
            for hourlyWeather in data.hourlyWeathers {
                modelContext.delete(hourlyWeather)
            }
            // 그 다음 LocationWeather 삭제
            modelContext.delete(data)
            print("🗑️ [WeatherSyncUseCase] Deleted weather data for \(data.city) with \(data.hourlyWeathers.count) hourly records")
        }
        
        try modelContext.save()
    }
    
    private func clearOldDateData() async throws {
        let today = Calendar.current.startOfDay(for: Date())
        let fetchDescriptor = FetchDescriptor<LocationWeather>()
        let allData = try modelContext.fetch(fetchDescriptor)
        
        let dataToDelete = allData.filter { data in
            !Calendar.current.isDate(data.date, inSameDayAs: today)
        }
        
        for data in dataToDelete {
            // HourlyWeather들을 먼저 명시적으로 삭제
            for hourlyWeather in data.hourlyWeathers {
                modelContext.delete(hourlyWeather)
            }
            // 그 다음 LocationWeather 삭제
            modelContext.delete(data)
            print("🗑️ [WeatherSyncUseCase] Deleted old weather data for \(data.date) with \(data.hourlyWeathers.count) hourly records")
        }
        
        try modelContext.save()
    }
    
    private func clearOldData(for locationInfo: LocationInfo) async throws {
        let currentDate = Calendar.current.startOfDay(for: Date())
        let fetchDescriptor = FetchDescriptor<LocationWeather>()
        let allData = try modelContext.fetch(fetchDescriptor)
        
        let dataToDelete = allData.filter { data in
            // 다른 위치이거나 다른 날짜인 데이터 삭제
            let isDifferentLocation = data.latitude != locationInfo.latitude || data.longitude != locationInfo.longitude
            let isDifferentDate = !Calendar.current.isDate(data.date, inSameDayAs: currentDate)
            return isDifferentLocation || isDifferentDate
        }
        
        for data in dataToDelete {
            // HourlyWeather들을 먼저 명시적으로 삭제
            for hourlyWeather in data.hourlyWeathers {
                modelContext.delete(hourlyWeather)
            }
            // 그 다음 LocationWeather 삭제
            modelContext.delete(data)
            print("🗑️ [WeatherSyncUseCase] Deleted old data for \(data.city) - \(data.date) with \(data.hourlyWeathers.count) hourly records")
        }
        
        try modelContext.save()
    }
    
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
            print("🗑️ [WeatherSyncUseCase] Removed existing data with same ID: \(locationId)")
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
        
        print("✅ [WeatherSyncUseCase] Successfully saved weather data for \(locationInfo.city)")
        return locationWeather
    }
    
    private func convertRawDataToEntity(rawData: Weather, locationInfo: LocationInfo, targetDate: Date) -> LocationWeather {
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
        
        print("📊 [WeatherSyncUseCase] Filtered hourly data count: \(filteredHourlyData.count)")
        
        let hourlyEntities = filteredHourlyData.map { hourlyForecast in
            let hourlyWeather = HourlyWeather(
                date: hourlyForecast.date,
                uvIndex: Double(hourlyForecast.uvIndex.value),
                temperature: hourlyForecast.temperature.value
            )
            hourlyWeather.locationWeather = locationWeather
            return hourlyWeather
        }
        
        locationWeather.hourlyWeathers = hourlyEntities
        return locationWeather
    }
}
