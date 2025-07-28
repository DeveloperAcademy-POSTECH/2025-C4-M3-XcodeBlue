//
//  LocationWeather.swift
//  TarTanning
//
//  Created by Jun on 7/17/25.
//

import Foundation
import SwiftData

@Model
final class LocationWeather {
    @Attribute(.unique) var id: String
    var date: Date
    var latitude: Double
    var longitude: Double
    var city: String
    var sunriseTime: Date?
    var sunsetTime: Date?
    
    // HourlyWeather과의 관계
    @Relationship(deleteRule: .cascade) var hourlyWeathers: [HourlyWeather] = []
    
    init(date: Date, locationInfo: LocationInfo, sunriseTime: Date?, sunsetTime: Date?, hourlyWeathers: [HourlyWeather] = []) {
        self.id = "\(locationInfo.latitude),\(locationInfo.longitude)_\(date.formatted(.iso8601.year().month().day()))"
        self.date = Calendar.current.startOfDay(for: date)
        self.latitude = locationInfo.latitude
        self.longitude = locationInfo.longitude
        self.city = locationInfo.city
        self.sunriseTime = sunriseTime
        self.sunsetTime = sunsetTime
        self.hourlyWeathers = hourlyWeathers
    }
}

extension LocationWeather {
    func currentUVIndex(at date: Date = Date()) -> Double? {
        // 현재 시간의 시간(Hour)만 추출
        let currentHour = Calendar.current.component(.hour, from: date)
        
        // hourlyWeathers 중 현재 시간과 일치하는 hour를 찾음
        // 또는 가장 가까운 시간대의 UV index를 가져올 수도 있음
        let closestWeather = hourlyWeathers.min(by: { abs($0.hour - currentHour) < abs($1.hour - currentHour) })

        return closestWeather?.uvIndex
    }
}
