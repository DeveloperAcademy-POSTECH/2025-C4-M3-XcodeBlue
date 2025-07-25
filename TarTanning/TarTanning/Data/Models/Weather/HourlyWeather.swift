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
    var latitude: Double
    var longitude: Double
    var city: String
    var hour: Int { Calendar.current.component(.hour, from: date) }

    init(
        date: Date,
        uvIndex: Double,
        temperature: Double,
        latitude: Double,
        longitude: Double,
        city: String
    ) {
        self.date = date
        self.uvIndex = uvIndex
        self.temperature = temperature
        self.latitude = latitude
        self.longitude = longitude
        self.city = city
    }

}
