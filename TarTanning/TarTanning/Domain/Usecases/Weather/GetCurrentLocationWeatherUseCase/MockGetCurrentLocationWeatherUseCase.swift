//
//  MockGetCurrentLocationWeatherUseCase.swift
//  TarTanning
//
//  Created by Jun on 7/26/25.
//

import Foundation

final class MockGetCurrentLocationWeatherUseCase: GetCurrentLocationWeatherUseCaseProtocol {
    let mockLocation = LocationInfo.mockSeoul
    
    func execute() async throws -> LocationWeather {
        return try await WeatherKitManager.shared.fetchLocationWeather(for: mockLocation)
    }
    
    func getUVInfo() async -> UVInfo? {
        return await WeatherKitManager.shared.fetchUVInfo(for: mockLocation)
    }
}
