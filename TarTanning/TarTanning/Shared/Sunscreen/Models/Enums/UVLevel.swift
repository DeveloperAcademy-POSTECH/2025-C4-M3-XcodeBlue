//
//  UVLevel.swift
//  TarTanning
//
//  Created by taeni on 7/28/25.
//

import SwiftUI

enum UVLevel: String {
    case safe = "안전"
    case caution = "주의"
    case danger = "위험"
    case bad = "매우위험"

    var color: Color {
        switch self {
        case .safe: return .gaugeBackgroundSafe
        case .caution: return .gaugeBackgroundCaution
        case .danger: return .gaugeBackgroundDanger
        case .bad: return .gaugeBackgroundBad
        }
    }
}
