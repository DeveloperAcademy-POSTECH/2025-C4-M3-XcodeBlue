//
//  LocationWeather.swift
//  TarTanning
//
//  Created by Jun on 7/17/25.
//

import Foundation

struct LocationWeather{
    var date: Date
    
    // Core Location에서 오는 정보
    var city: String // 포항시, 대구광역시
    var latitude: Double
    var longitude: Double
    
    // WeatherKit으로부터 오는 정보
    var sunriseTime: Date? // 해당 일출 시간
    var sunsetTime: Date? // 해당 일몰 시간
    var hourlyWeathers: [HourlyWeather]
    
    init(date: Date, city: String, latitude: Double, longitude: Double, sunriseTime: Date? = nil, sunsetTime: Date? = nil, hourlyWeathers: [HourlyWeather]) {
        self.date = date
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
        self.sunriseTime = sunriseTime
        self.sunsetTime = sunsetTime
        self.hourlyWeathers = hourlyWeathers
    }
}


