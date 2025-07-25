//
//  SPFLevel.swift
//  TarTanning
//
//  Created by J on 7/22/25.
//

import Foundation

enum SPFLevel: Int, CaseIterable, Identifiable, Codable {
    case spf15 = 15
    case spf30 = 30
    case spf40 = 40
    case spf50 = 50
    case spf60 = 60
    case spf70 = 70
    case spf80 = 80
    case spf90 = 90
    case spf100 = 100

    var id: Int { rawValue }

    var displayTitle: String {
        if .spf100 == self {
            return "SPF \(rawValue) 이상"
        }
        return "SPF \(rawValue)"
    }
}
