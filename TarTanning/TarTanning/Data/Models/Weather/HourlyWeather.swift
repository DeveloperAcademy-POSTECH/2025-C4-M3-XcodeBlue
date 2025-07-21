//
//  HourlyWeather.swift
//  TarTanning
//
//  Created by Jun on 7/17/25.
//

import Foundation

struct HourlyWeather: Codable {
    var hour: Int // 해당 시간 (0~23시)
    var uvIndex: Double // UV 지수 값 : 4.0
    var temperature: Double // 기온 : 29.9도
}

extension HourlyWeather {
    static let mockHourlyWeather: [HourlyWeather] = [
        HourlyWeather(hour: 0, uvIndex: 0.0, temperature: 22.5),
        HourlyWeather(hour: 1, uvIndex: 0.0, temperature: 21.8),
        HourlyWeather(hour: 2, uvIndex: 0.0, temperature: 21.2),
        HourlyWeather(hour: 3, uvIndex: 0.0, temperature: 20.7),
        HourlyWeather(hour: 4, uvIndex: 0.0, temperature: 20.3),
        HourlyWeather(hour: 5, uvIndex: 0.1, temperature: 20.1),
        HourlyWeather(hour: 6, uvIndex: 0.5, temperature: 21.5),
        HourlyWeather(hour: 7, uvIndex: 1.2, temperature: 23.8),
        HourlyWeather(hour: 8, uvIndex: 2.8, temperature: 26.2),
        HourlyWeather(hour: 9, uvIndex: 4.5, temperature: 28.7),
        HourlyWeather(hour: 10, uvIndex: 6.2, temperature: 30.1),
        HourlyWeather(hour: 11, uvIndex: 7.8, temperature: 31.5),
        HourlyWeather(hour: 12, uvIndex: 8.5, temperature: 32.2),
        HourlyWeather(hour: 13, uvIndex: 8.2, temperature: 32.8),
        HourlyWeather(hour: 14, uvIndex: 7.1, temperature: 32.1),
        HourlyWeather(hour: 15, uvIndex: 5.8, temperature: 31.3),
        HourlyWeather(hour: 16, uvIndex: 4.2, temperature: 30.2),
        HourlyWeather(hour: 17, uvIndex: 2.5, temperature: 28.9),
        HourlyWeather(hour: 18, uvIndex: 1.1, temperature: 27.1),
        HourlyWeather(hour: 19, uvIndex: 0.3, temperature: 25.8),
        HourlyWeather(hour: 20, uvIndex: 0.0, temperature: 24.5),
        HourlyWeather(hour: 21, uvIndex: 0.0, temperature: 23.7),
        HourlyWeather(hour: 22, uvIndex: 0.0, temperature: 23.1),
        HourlyWeather(hour: 23, uvIndex: 0.0, temperature: 22.8)
    ]
}
