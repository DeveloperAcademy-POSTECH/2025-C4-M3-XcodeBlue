//
//  WeatherManager.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import CoreLocation
import Foundation
import WeatherKit

struct UVInfo {
    let value: Int
    let category: String
}

final class WeatherKitManager {
    static let shared = WeatherKitManager()
    private init() {}

    private let weatherService = WeatherService.shared

    func fetchUVInfo(for location: LocationInfo) async -> UVInfo? {
        do {
            let weather = try await weatherService.weather(for: location.asCLLocation)
            let uvIndex = weather.currentWeather.uvIndex
            
            let categoryString: String
            switch uvIndex.category {
            case .low:
                categoryString = "낮음"
            case .moderate:
                categoryString = "보통"
            case .high:
                categoryString = "높음"
            case .veryHigh:
                categoryString = "매우 높음"
            case .extreme:
                categoryString = "위험"
            @unknown default:
                categoryString = "알 수 없음"
            }
            
            return UVInfo(value: uvIndex.value, category: categoryString)
            
        } catch {
            print("WeatherKit 데이터 가져오기 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchLocationWeather(for locationInfo: LocationInfo) async throws -> LocationWeather {
        let weather = try await weatherService.weather(for: locationInfo.asCLLocation)
        let now = Date()

        // 4AM-11PM 시간대만 필터링하고 위치 정보 포함
        let hourlyWeathers: [HourlyWeather] = weather.hourlyForecast.forecast
            .filter { hour in
                let hourOfDay = Calendar.current.component(.hour, from: hour.date)
                return hourOfDay >= 4 && hourOfDay <= 23 // 4AM-11PM
            }
            .map { hour in
                HourlyWeather(
                    date: hour.date,
                    uvIndex: Double(hour.uvIndex.value),
                    temperature: hour.temperature.value,
                    latitude: locationInfo.latitude,
                    longitude: locationInfo.longitude,
                    city: locationInfo.city
                )
            }

        let sunrise = weather.dailyForecast.forecast.first?.sun.sunrise
        let sunset = weather.dailyForecast.forecast.first?.sun.sunset

        return LocationWeather(
            date: now,
            locationInfo: locationInfo,
            sunriseTime: sunrise,
            sunsetTime: sunset,
            hourlyWeathers: hourlyWeathers  // hourlyWeathers 전달
        )
    }
    
    // 4AM-11PM 시간대 UV 지수만 조회하는 별도 메서드
    func fetchHourlyUVData(for locationInfo: LocationInfo) async throws -> [HourlyWeather] {
        let weather = try await weatherService.weather(for: locationInfo.asCLLocation)
        let calendar = Calendar.current
        
        return weather.hourlyForecast.forecast
            .filter { hour in
                let hourOfDay = calendar.component(.hour, from: hour.date)
                return hourOfDay >= 4 && hourOfDay <= 23 // 4AM-11PM
            }
            .map { hour in
                HourlyWeather(
                    date: hour.date,
                    uvIndex: Double(hour.uvIndex.value),
                    temperature: hour.temperature.value,
                    latitude: locationInfo.latitude,
                    longitude: locationInfo.longitude,
                    city: locationInfo.city
                )
            }
    }
}
