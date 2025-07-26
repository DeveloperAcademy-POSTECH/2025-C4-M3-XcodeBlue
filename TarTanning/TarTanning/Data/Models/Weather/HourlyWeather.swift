//
//  HourlyWeather.swift
//  TarTanning
//
//  Created by Jun on 7/17/25.
//

import Foundation
import SwiftData

@Model
final class HourlyWeather {
    var date: Date
    var uvIndex: Double
    var temperature: Double
    var hour: Int { Calendar.current.component(.hour, from: date) }
    var locationWeather: LocationWeather?

    init(date: Date, uvIndex: Double, temperature: Double) {
        self.date = date
        self.uvIndex = uvIndex
        self.temperature = temperature
    }
}
