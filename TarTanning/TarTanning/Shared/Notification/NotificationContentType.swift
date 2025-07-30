//
//  NotificationContentType.swift
//  TarTanning
//
//  Created by J on 7/17/25.
//

import Foundation

enum NotificationContentType {
    case medWarning(percent: Int)
    case sunscreenReminder(uvIndex: Int)
    case sunscreenPrompt
}

extension NotificationContentType {
    var id: String {
        switch self {
        case .medWarning(let percent):
            return "med-\(percent)"
        case .sunscreenReminder(let unIndex):
            return "sunscreen-uv\(unIndex)"
        case .sunscreenPrompt:
            return "sunscreen-prompt"
        }
    }
    
    var title: String {
        switch self {
        case .medWarning(let percent):
            switch percent {
            case 0..<30:
                return "MED \(percent) · 낮은 수준"
            case 30..<50:
                return "MED \(percent) · 보통 수준"
            case 50..<70:
                return "MED \(percent) · 주의 수준"
            case 70...:
                return "MED \(percent) · 높은 수준"
            default:
                return "MED · 알림"
            }
        case .sunscreenReminder:
            return "선크림, 잊지 마세요!"
        case .sunscreenPrompt:
            return "선크림 타이머가 끝났습니다."
        }
    }
    
    var body: String {
        switch self {
        case .medWarning(let percent):
            switch percent {
            case 0..<30:
                return "자외선 노출이 낮은 수준입니다. 현재 수준의 야외 활동이 가능합니다."
            case 30..<50:
                return "자외선 노출이 적정 수준입니다. 자외선 차단을 고려해보세요."
            case 50..<70:
                return "자외선 노출이 많이 누적되었습니다. 자외선 차단을 권장합니다."
            case 70...:
                return "자외선 노출이 높은 수준입니다. 실내 활동을 고려해보세요."
            default:
                return "자외선 누적 상태를 확인 중입니다."
            }
            
        case .sunscreenReminder(let uvIndex):
            switch uvIndex {
            case 0..<3:
                return "지수는 낮지만, 민감한 피부는 선크림을 챙기는 게 좋아요."
            case 3..<6:
                return "자외선 지수가 보통이에요. 외출 전 선크림을 꼭 발라주세요."
            case 6..<8:
                return "강한 자외선! SPF 30 이상 선크림을 바르세요."
            case 8...:
                return "매우 강한 자외선! 장시간 외출은 피하고, 선크림은 필수예요."
            default:
                return "현재 자외선 수치 정보가 불확실해요. 주의가 필요해요."
            }
        case .sunscreenPrompt:
            return "선크림은 매 2시간마다 덧발라야합니다. 지금 덧바르시겠습니까?"
        }
    }
    
    var categoryIdentifier: String? {
        switch self {
        case .sunscreenPrompt:
            return "SUNSCREEN_CATEGORY"
        default:
            return nil
        }
    }
}
