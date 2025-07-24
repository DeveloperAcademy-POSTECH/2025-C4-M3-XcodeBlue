//
//  DailyWeatherCache.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

import Foundation
import SwiftData

@Model
class DailyWeatherCache {
    var city: String                    // "포항시"
    var currentDate: Date
    var hourlyUVIndex: [Int: Double]    // 시간별 UV 지수 [시간: UV지수]
    var sunrise: Date?                  // 일출 시간
    var sunset: Date?                   // 일몰 시간
    var temperature: [Int: Double]      // 시간별 온도 [시간: 온도]
    
    init(
        city: String,
        currentDate: Date = Date(),
        hourlyUVIndex: [Int: Double] = [:],
        sunrise: Date? = nil,
        sunset: Date? = nil,
        temperature: [Int: Double] = [:]
    ) {
        self.city = city
        self.currentDate = currentDate
        self.hourlyUVIndex = hourlyUVIndex
        self.sunrise = sunrise
        self.sunset = sunset
        self.temperature = temperature
    }
}

// MARK: - Convenience Extensions

extension DailyWeatherCache {
    
    /// 현재 시간의 UV 지수 가져오기
    var currentUVIndex: Double {
        let currentHour = Calendar.current.component(.hour, from: Date())
        return hourlyUVIndex[currentHour] ?? 0.0
    }
    
    /// 현재 시간의 온도 가져오기
    var currentTemperature: Double {
        let currentHour = Calendar.current.component(.hour, from: Date())
        return temperature[currentHour] ?? 0.0
    }
    
    /// 특정 시간의 UV 지수 가져오기
    func uvIndex(at hour: Int) -> Double {
        return hourlyUVIndex[hour] ?? 0.0
    }
    
    /// 특정 시간의 온도 가져오기
    func temperature(at hour: Int) -> Double {
        return temperature[hour] ?? 0.0
    }
    
    /// 시간 범위의 평균 UV 지수 계산
    func averageUVIndex(from startHour: Int, to endHour: Int) -> Double {
        let hours = startHour == endHour ? [startHour] : Array(startHour...endHour)
        let uvValues = hours.compactMap { hourlyUVIndex[$0] }.filter { $0 > 0 }
        
        guard !uvValues.isEmpty else { return 0.0 }
        return uvValues.reduce(0, +) / Double(uvValues.count)
    }
    
    /// 오늘인지 확인
    var isToday: Bool {
        Calendar.current.isDateInToday(currentDate)
    }
    
    /// 일출/일몰 시간이 설정되어 있는지 확인
    var hasSunTimes: Bool {
        sunrise != nil && sunset != nil
    }
}

extension DailyWeatherCache {
    convenience init(from locationWeather: LocationWeather) {
        let hourlyUV = Dictionary(
            uniqueKeysWithValues: locationWeather.hourlyWeathers.map {
                (Calendar.current.component(.hour, from: $0.date), $0.uvIndex)
            }
        )
        
        let hourlyTemp = Dictionary(
            uniqueKeysWithValues: locationWeather.hourlyWeathers.map {
                (Calendar.current.component(.hour, from: $0.date), $0.temperature)
            }
        )
        
        self.init(
            city: locationWeather.locationInfo.city,
            currentDate: locationWeather.date,
            hourlyUVIndex: hourlyUV,
            sunrise: locationWeather.sunriseTime,
            sunset: locationWeather.sunsetTime,
            temperature: hourlyTemp
        )
    }
}
