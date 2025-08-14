//
//  WeatherKitManager.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import CoreLocation
import Foundation
import WeatherKit

final class WeatherKitManagerNew {
    static let shared = WeatherKitManagerNew()
    
    private let weatherService = WeatherService.shared
    
    private init() {}
    
    /// 특정 위치의 현재 날씨 정보 조회
    /// 매개변수: LocationInfo (외부에서 주입받음)
    /// 반환값: CurrentWeather
    func fetchCurrentWeather(for locationInfo: LocationInfo) async throws -> CurrentWeather {
        do{
            let weather = try await weatherService.weather(
                for: locationInfo.asCLLocation,
                including: .current
            )
            return weather
        } catch {
            throw WeatherManagerError.weatherDataFetchFailed
        }
    }
}
