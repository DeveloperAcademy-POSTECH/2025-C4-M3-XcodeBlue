//
//  UVExposeRecord.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation
import SwiftData

@Model
class UVExposeRecord {
    var startDate: Date  // HealthKit에서 받은 일광 시작 시간
    var endDate: Date  // HealthKit에서 받은 일광 종료 시간
    var sunlightExposureDuration: Double  // HealthKit에서 받은 일광 시간 (분)
    var uvDose: Double  // 계산된 홍반량 (나중에 저장)
    var isSPFApplied: Bool  // 선크림 발랐는지 여부
    var dailyExposure: DailyUVExpose?  // 관계 설정

    init(
        startDate: Date,
        endDate: Date,
        sunlightExposureDuration: Double,
        isSPFApplied: Bool = false
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.sunlightExposureDuration = sunlightExposureDuration
        self.uvDose = 0.0  // 나중에 계산해서 저장
        self.isSPFApplied = isSPFApplied
        self.dailyExposure = nil
    }
}
