//
//  UserProfile.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation
import SwiftUI
import SwiftData

@Model
class UserProfile {
    var skinType: SkinType
    var currentSpfIndex: Int = 30 // 사용자가 설정한 SPF (기본값 30)
    var spfDate: Date? // SPF 발라진 날짜/시간
    var dailyExposures: [DailyUVExpose] = []
    
    init(skinType: SkinType) {
        self.skinType = skinType
        self.currentSpfIndex = 30 // 기본값 설정
    }
}
