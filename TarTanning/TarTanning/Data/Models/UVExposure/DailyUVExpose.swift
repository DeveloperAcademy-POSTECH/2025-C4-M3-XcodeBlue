//
//  DailyUVExposure.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation
import SwiftData

/// 날짜별 사용자의 전체 일광시간, UV노출량 기록을 담는 데이터 구조
@Model
class DailyUVExpose {
    var date: Date
    var exposureRecords: [UVExposeRecord] = []
    var totalUVDose: Double = 0.0
    var totalSunlightMinutes: Double = 0.0
    var spfIndex: Int? // 해당 날짜에 사용한 SPF
    var spfDate: Date? // SPF 발라진 시간
    
    init(date: Date) {
        self.date = date
    }
}
