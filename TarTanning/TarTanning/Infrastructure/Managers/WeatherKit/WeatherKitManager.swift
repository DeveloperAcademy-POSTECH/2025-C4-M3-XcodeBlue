//
//  WeatherKitManager.swift
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
    
    private let weatherService = WeatherService.shared
    
    private init() {}
    
    func fetchUVInfo(for locationInfo: LocationInfo) async -> UVInfo? {
        do {
            let weather = try await weatherService.weather(for: locationInfo.asCLLocation)
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
            print("❌ WeatherKit 데이터 가져오기 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchRawWeatherData(for locationInfo: LocationInfo) async throws -> Weather {
        print("🌐 Fetching raw weather data for \(locationInfo.city)")
        return try await weatherService.weather(for: locationInfo.asCLLocation)
    }
}
