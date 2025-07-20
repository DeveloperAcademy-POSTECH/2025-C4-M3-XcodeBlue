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

extension UVExposeRecord {
    /// 일광 시간 기록들 Mock 데이터 (현재 날짜 기준)
    static var mockExposureRecords: [UVExposeRecord] {
        let calendar = Calendar.current
        let today = Date()
        
        // 현재 날짜를 기준으로 Mock 데이터 생성
        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)
        let currentDay = calendar.component(.day, from: today)
        
        return [
            // 오늘 날짜 - 여러 개 세션 (실제 UV가 있는 시간대)
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: currentDay, hour: 9, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: currentDay, hour: 9, minute: 20))!,
                sunlightExposureDuration: 20.0,
                isSPFApplied: true
            ),
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: currentDay, hour: 13, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: currentDay, hour: 13, minute: 25))!,
                sunlightExposureDuration: 25.0,
                isSPFApplied: true
            ),
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: currentDay, hour: 17, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: currentDay, hour: 17, minute: 15))!,
                sunlightExposureDuration: 15.0,
                isSPFApplied: false
            )
        ]
    }
}
