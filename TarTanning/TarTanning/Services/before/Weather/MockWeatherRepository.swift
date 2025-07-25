//
//  MockWeatherRepository.swift
//  TarTanning
//
//  Created by Jun on 7/20/25.
//

import Foundation

class MockWeatherRepository: WeatherRepository {
    func getCurrentWeather() async throws -> LocationWeather {
        return LocationWeather.mockLocationWeather
    }
}
