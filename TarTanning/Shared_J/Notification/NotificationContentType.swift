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
                return "MED 30﹒안전"
            case 30..<50:
                return "MED 50﹒주의"
            case 50..<70:
                return "지금은 자외선으로부터 위험해요"
            case 70...:
                return "지금은 자외선으로부터 나빠요"
            default:
                return "자외선 경고"
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
            case 30:
                return "자외선 "
            case 50:
                return "자외선 노출량이 50%에 도달했어요"
            case 70:
                return "자외선 노출량이 70%에 도달했어요"
            case 100:
                return "자외선 노출량이 100%에 도달했어요"
            default:
                return "자외선에 노출중입니다."
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
