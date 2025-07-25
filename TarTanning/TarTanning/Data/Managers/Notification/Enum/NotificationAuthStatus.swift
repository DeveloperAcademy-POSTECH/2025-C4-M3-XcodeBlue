//
//  NotificationAuthStatus.swift
//  TarTanning
//
//  Created by J on 7/17/25.
//

import Foundation

enum NotificationAuthStatus {
    case authorized
    case provisional
    case denied
    case notDetermined
    case notAvailable
    
    var description: String {
        switch self {
        case .notDetermined:
            return "권한 요청 안됨"
        case .denied:
            return "권한 거부됨"
        case .authorized:
            return "권한 허용됨"
        case .provisional:
            return "임시 허용됨"
        case .notAvailable:
            return "알림 기능 사용 불가"
        }
    }
    
    var isAuthorized: Bool {
        return self == .authorized || self == .provisional
    }
}
