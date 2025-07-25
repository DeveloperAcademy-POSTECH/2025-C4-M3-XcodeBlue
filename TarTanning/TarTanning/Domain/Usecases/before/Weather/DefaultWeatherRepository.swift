//
//  DefaultWeatherRepository.swift
//  TarTanning
//
//  Created by Jun on 7/22/25.
//

import Foundation

class DefaultWeatherRepository: WeatherRepository {
    func getCurrentWeather() async throws -> LocationWeather {
        let location = LocationInfo.mockSeoul
        return try await WeatherKitManager.shared.fetchLocationWeather(for: location)
    }
}
