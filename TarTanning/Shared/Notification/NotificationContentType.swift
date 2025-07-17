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
}

extension NotificationContentType {
    var id: String {
        switch self {
        case .medWarning(let percent):
            return "med-\(percent)"
        case .sunscreenReminder(let unIndex):
            return "sunscreen-uv\(unIndex)"
        }
    }
    
    var title: String {
        switch self {
        case .medWarning(let percent):
            switch percent {
            case 0..<40:
                return "햇빛이 시작됐어요"
            case 40..<60:
                return "햇빛이 점점 강해져요"
            case 60..<90:
                return "자외선 누적이 높아요"
            case 90...:
                return "자외선 한계에 도달했어요!"
            default:
                return "자외선 경고"
            }
        case .sunscreenReminder:
            return "선크림, 잊지 마세요!"
        }
    }
    
    var body: String {
        switch self {
        case .medWarning(let percent):
            switch percent {
            case 30:
                return "자외선 노출량이 30%에 도달했어요"
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
        }
    }
}
