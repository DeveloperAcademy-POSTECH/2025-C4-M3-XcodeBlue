//
//  WeatherRepository.swift
//  TarTanning
//
//  Created by Jun on 7/20/25.
//

import Foundation

protocol WeatherRepository {
    func getCurrentWeather() async throws -> LocationWeather
    func getCurrentUVIndex() async throws 
}
