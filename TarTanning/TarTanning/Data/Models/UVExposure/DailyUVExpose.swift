//
//  DailyUVExposure.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation

/// 날짜별 사용자의 전체 일광시간, UV노출량 기록을 담는 데이터 구조
struct DailyUVExpose {
    let date: Date
    var exposureRecords: [UVExposeRecord] = []
    var totalUVDose: Double {
        exposureRecords.reduce(0) { $0 + $1.uvDose }
    }
    var totalSunlightMintues: Double {
        let totalMinutes = exposureRecords.reduce(0) {
            $0 + $1.sunlightExposureDuration
        }
        return totalMinutes
    }
}
