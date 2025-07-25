//
//  LocationWeather.swift
//  TarTanning
//
//  Created by Jun on 7/17/25.
//

import Foundation

struct LocationWeather {
    var date: Date
    var locationInfo: LocationInfo  // LocationInfo 포함
    var sunriseTime: Date?
    var sunsetTime: Date?
    var hourlyWeathers: [HourlyWeather]
    
    init(
        date: Date,
        locationInfo: LocationInfo,
        sunriseTime: Date? = nil,
        sunsetTime: Date? = nil,
        hourlyWeathers: [HourlyWeather]
    ) {
        self.date = date
        self.locationInfo = locationInfo
        self.sunriseTime = sunriseTime
        self.sunsetTime = sunsetTime
        self.hourlyWeathers = hourlyWeathers
    }
}

extension LocationWeather {
    static var mockLocationWeather: LocationWeather {
        let today = Date()
        let calendar = Calendar.current
        let sunriseTime = calendar.date(bySettingHour: 5, minute: 30, second: 0, of: today)!
        let sunsetTime = calendar.date(bySettingHour: 19, minute: 45, second: 0, of: today)!
        
        return LocationWeather(
            date: today,
            locationInfo: LocationInfo.mockSeoul,
            sunriseTime: sunriseTime,
            sunsetTime: sunsetTime,
            hourlyWeathers: HourlyWeather.mockHourlyWeather
        )
    }
}
