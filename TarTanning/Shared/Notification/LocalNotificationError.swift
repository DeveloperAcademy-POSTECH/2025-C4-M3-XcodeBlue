//
//  LocalNotificationError.swift
//  TarTanning (iOS + watchOS)
//
//  Created by J on 7/17/25.
//

import Foundation

enum LocalNotificationError: Error, LocalizedError {
    case authorizationDenied
    case scheduleFailed(String)
    case invalidDate
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "알림 권한이 거부되었습니다. 설정에서 권한을 허용해주세요."
        case .scheduleFailed(let message):
            return "알림 예약에 실패했습니다: \(message)"
        case .invalidDate:
            return "잘못된 날짜로 알림을 예약할 수 없습니다."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
