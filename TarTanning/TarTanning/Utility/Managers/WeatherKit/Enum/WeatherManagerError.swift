//
//  WeatherManagerError.swift
//  TarTanning
//
//  Created by Jun on 7/26/25.
//

import Foundation

enum WeatherManagerError: Error, LocalizedError {
    case locationUnavailable
    case contextUnavailable
    case weatherDataFetchFailed
    case noLocationPermission

    var errorDescription: String? {
        switch self {
        case .locationUnavailable:
            return "위치 정보를 사용할 수 없습니다"
        case .contextUnavailable:
            return "데이터베이스 컨텍스트를 사용할 수 없습니다"
        case .weatherDataFetchFailed:
            return "날씨 데이터를 불러올 수 없습니다"
        case .noLocationPermission:
            return "위치 권한이 필요합니다"
        }
    }
}
