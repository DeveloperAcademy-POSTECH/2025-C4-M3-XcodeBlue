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

    func fetchUVInfo(for location: CLLocation) async -> UVInfo? {
        do {
            let weather = try await weatherService.weather(for: location)
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
        let calendar = Calendar.current

        let hourlyWeathers: [HourlyWeather] = weather.hourlyForecast.forecast.map { hour in
            HourlyWeather(
                date: hour.date,
                uvIndex: Double(hour.uvIndex.value),
                temperature: hour.temperature.value
            )
        }

        let sunrise = weather.dailyForecast.forecast.first?.sun.sunrise
        let sunset = weather.dailyForecast.forecast.first?.sun.sunset

        return LocationWeather(
            date: now,
            locationInfo: locationInfo,
            sunriseTime: sunrise,
            sunsetTime: sunset,
            hourlyWeathers: hourlyWeathers
        )
    }
}
