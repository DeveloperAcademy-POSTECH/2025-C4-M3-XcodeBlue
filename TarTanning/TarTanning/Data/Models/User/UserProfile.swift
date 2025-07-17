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
    var currentSpfIndex: Int?
    var spfDate: Date? // SPF 발라진 날짜/시간
    var dailyExposures: [DailyUVExpose] = []
    
    init(skinType: SkinType) {
        self.skinType = skinType
    }
}
