//
//  LocationError.swift
//  TarTanning
//
//  Created by J on 7/19/25.
//

import Foundation

enum LocationError: Error, LocalizedError {
    case servicesDisabled
    case permissionDenied
    case restricted
    case unknownAuthorizationStatus
    case noLocationFound
    case geocodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .servicesDisabled:
            return "위치 서비스가 비활성화되어 있습니다."
        case .permissionDenied:
            return "위치 권한이 거부되었습니다."
        case .restricted:
            return "위치 서비스 사용이 제한되어 있습니다."
        case .unknownAuthorizationStatus:
            return "알 수 없는 위치 권한 상태입니다."
        case .noLocationFound:
            return "현재 위치를 가져올 수 없습니다."
        case .geocodingFailed(let error):
            return "주소 정보를 찾지 못했습니다: \(error.localizedDescription)"
        }
    }
}
