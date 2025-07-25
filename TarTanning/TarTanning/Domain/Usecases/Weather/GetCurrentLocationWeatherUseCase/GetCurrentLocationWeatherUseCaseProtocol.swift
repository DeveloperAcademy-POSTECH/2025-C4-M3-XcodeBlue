//
//  GetCurrentLocationWeatherUseCaseProtocol.swift
//  TarTanning
//
//  Created by Jun on 7/26/25.
//

import Foundation

protocol GetCurrentLocationWeatherUseCaseProtocol {
    func execute() async throws -> LocationWeather
    func getUVInfo() async -> UVInfo?
}
