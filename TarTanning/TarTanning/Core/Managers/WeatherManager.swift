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
    let value: Double
    let category: String
    let sunrise: Date?
    let sunset: Date?
}

final class WeatherKitManager {
    static let shared = WeatherKitManager()
    private init() {}

    private let weatherService = WeatherService.shared

    func fetchUVInfo(for location: CLLocation) async -> UVInfo? {
        do {
            let (currentWeather, dailyForecast) = try await weatherService.weather(for: location, including: .current, .daily)
          
            guard let todayForecast = dailyForecast.first(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) else {
                          print("⚠️ 경고: 오늘의 일일 예보를 찾을 수 없습니다.")
                          return nil // 오늘의 예보를 찾을 수 없으면 nil 반환
                      }
          
            let sunrise = todayForecast.sun.sunrise
            let sunset = todayForecast.sun.sunset
            let uvIndex = currentWeather.uvIndex
            
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
            
          return UVInfo(value: Double(uvIndex.value), category: categoryString, sunrise: sunrise, sunset: sunset)
            
        } catch {
            print("WeatherKit 데이터 가져오기 실패: \(error.localizedDescription)")
            return nil
        }
    }
}
