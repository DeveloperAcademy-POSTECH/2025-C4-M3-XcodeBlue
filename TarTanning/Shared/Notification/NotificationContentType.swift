//
//  NotificationContentType.swift
//  TarTanning (iOS + watchOS)
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
                return "MED \(percent) · 안전"
            case 30..<50:
                return "MED \(percent) · 주의"
            case 50..<70:
                return "MED \(percent) · 위험"
            case 70...:
                return "MED \(percent) · 나쁨"
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
                return "자외선 노출이 아직 낮은 편이에요. 지금처럼 활동해도 안전해요."
            case 30..<50:
                return "자외선 노출이 점차 쌓이고 있어요. 주의가 필요한 시점이에요."
            case 50..<70:
                return "자외선 노출이 많이 누적됐어요. 가능한 한 햇빛을 피해주세요."
            case 70...:
                return "자외선 누적이 매우 높아요. 당장 실내로 이동하는 걸 권장해요."
            default:
                return "자외선 누적 상태를 확인하고 있어요."
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
