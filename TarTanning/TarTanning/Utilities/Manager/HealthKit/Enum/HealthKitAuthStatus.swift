//
//  HealthKitAuthStatus.swift
//  TarTanning
//
//  Created by taeni on 7/15/25.
//

enum HealthKitAuthStatus {
    case notDetermined  // 아직 권한 요청하지 않음
    case denied         // 사용자가 거부함
    case authorized     // 사용자가 허용함
    case notAvailable   // HealthKit 사용 불가능
    
    var description: String {
        switch self {
        case .notDetermined:
            return "권한 요청 안됨"
        case .denied:
            return "권한 거부됨"
        case .authorized:
            return "권한 허용됨"
        case .notAvailable:
            return "HealthKit 사용 불가"
        }
    }
    
    var isAuthorized: Bool {
        return self == .authorized
    }
}
