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
    var startDate: Date                    // HealthKit에서 받은 일광 시작 시간
    var endDate: Date                      // HealthKit에서 받은 일광 종료 시간
    var sunlightExposureDuration: Double   // HealthKit에서 받은 일광 시간 (분)
    var uvDose: Double                     // 계산된 홍반량 (나중에 저장)
    var isSPFApplied: Bool                 // 선크림 발랐는지 여부
    var dailyExposure: DailyUVExpose?      // 관계 설정

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

extension UVExposeRecord {
    static var mockTodayExposureRecords: [UVExposeRecord] {
        let today = Date()
        let calendar = Calendar.current

        return [
            // HealthKit에서 받은 첫 번째 일광 데이터 (5분) - 선크림 발랐음
            UVExposeRecord(
                startDate: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 9, minute: 35, second: 0, of: today)!,
                sunlightExposureDuration: 5.0,
                isSPFApplied: true
            ),

            // HealthKit에서 받은 두 번째 일광 데이터 (10분) - 선크림 발랐음
            UVExposeRecord(
                startDate: calendar.date(bySettingHour: 9, minute: 35, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 9, minute: 45, second: 0, of: today)!,
                sunlightExposureDuration: 10.0,
                isSPFApplied: true
            ),

            // HealthKit에서 받은 세 번째 일광 데이터 (15분) - 선크림 안 발랐음
            UVExposeRecord(
                startDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 12, minute: 15, second: 0, of: today)!,
                sunlightExposureDuration: 15.0,
                isSPFApplied: false
            ),

            // HealthKit에서 받은 네 번째 일광 데이터 (20분) - 선크림 안 발랐음
            UVExposeRecord(
                startDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 16, minute: 20, second: 0, of: today)!,
                sunlightExposureDuration: 20.0,
                isSPFApplied: false
            ),

            // HealthKit에서 받은 다섯 번째 일광 데이터 (8분) - 선크림 발랐음
            UVExposeRecord(
                startDate: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 18, minute: 38, second: 0, of: today)!,
                sunlightExposureDuration: 8.0,
                isSPFApplied: true
            )
        ]
    }
}
