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

    init(date: Date) {
        self.date = date
    }
}

extension DailyUVExpose {
    /// 오늘 기준 일일 UV 노출 요약 Mock 데이터
    static var mockTodayDailyExposure: DailyUVExpose {
        let today = Date()
        let dailyExposure = DailyUVExpose(date: today)

        // 오늘 날짜의 UVExposeRecord들만 필터링
        let todayRecords = UVExposeRecord.mockExposureRecords.filter {
            Calendar.current.isDate($0.startDate, inSameDayAs: today)
        }

        dailyExposure.exposureRecords = todayRecords
        dailyExposure.totalSunlightMinutes = todayRecords.reduce(0) {
            $0 + $1.sunlightExposureDuration
        }
        dailyExposure.totalUVDose = todayRecords.reduce(0) { $0 + $1.uvDose }

        return dailyExposure
    }
}
