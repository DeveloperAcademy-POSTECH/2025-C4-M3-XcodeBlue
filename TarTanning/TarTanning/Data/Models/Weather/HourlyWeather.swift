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
