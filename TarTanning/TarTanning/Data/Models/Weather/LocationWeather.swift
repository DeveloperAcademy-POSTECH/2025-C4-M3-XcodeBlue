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
