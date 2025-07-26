//
//  CoreLocationAuthStatus.swift
//  TarTanning
//
//  Created by J on 7/19/25.
//

import CoreLocation
import Foundation

enum LocationAuthStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
    case notAvailable
    
    var description: String {
        switch self {
        case .notDetermined:
            return "권한 요청 안됨"
        case .denied:
            return "권한 거부됨"
        case .authorized:
            return "권한 허용됨"
        case .restricted:
            return "제한됨"
        case .notAvailable:
            return "HealthKit 사용 불가"
        }
    }
    
    var isAuthorized: Bool {
        self == .authorized
    }
}
