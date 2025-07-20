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
    /// 일광 시간 기록들 Mock 데이터 (7월 10일 ~ 7월 30일)
    static var mockExposureRecords: [UVExposeRecord] {
        let calendar = Calendar.current
        
        return [
            // 7월 10일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 10, hour: 9, minute: 30))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 10, hour: 9, minute: 35))!,
                sunlightExposureDuration: 5.0,
                isSPFApplied: true
            ),
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 10, hour: 12, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 10, hour: 12, minute: 15))!,
                sunlightExposureDuration: 15.0,
                isSPFApplied: true
            ),
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 10, hour: 16, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 10, hour: 16, minute: 10))!,
                sunlightExposureDuration: 10.0,
                isSPFApplied: false
            ),

            // 7월 11일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 11, hour: 10, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 11, hour: 10, minute: 8))!,
                sunlightExposureDuration: 8.0,
                isSPFApplied: true
            ),
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 11, hour: 14, minute: 30))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 11, hour: 15, minute: 20))!,
                sunlightExposureDuration: 50.0,
                isSPFApplied: true
            ),

            // 7월 12일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 12, hour: 11, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 12, hour: 11, minute: 25))!,
                sunlightExposureDuration: 25.0,
                isSPFApplied: false
            ),
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 12, hour: 16, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 12, hour: 16, minute: 30))!,
                sunlightExposureDuration: 30.0,
                isSPFApplied: false
            ),

            // 7월 13일 - 기록 없음

            // 7월 14일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 14, hour: 9, minute: 45))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 14, hour: 9, minute: 50))!,
                sunlightExposureDuration: 5.0,
                isSPFApplied: true
            ),

            // 7월 15일 - 기록 없음

            // 7월 16일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 16, hour: 13, minute: 15))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 16, hour: 13, minute: 35))!,
                sunlightExposureDuration: 20.0,
                isSPFApplied: true
            ),

            // 7월 17일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 17, hour: 14, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 17, hour: 14, minute: 2))!,
                sunlightExposureDuration: 2.0,
                isSPFApplied: false
            ),

            // 7월 18일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 18, hour: 8, minute: 30))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 18, hour: 8, minute: 45))!,
                sunlightExposureDuration: 15.0,
                isSPFApplied: true
            ),
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 18, hour: 15, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 18, hour: 15, minute: 30))!,
                sunlightExposureDuration: 30.0,
                isSPFApplied: false
            ),

            // 7월 19일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 19, hour: 10, minute: 15))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 19, hour: 10, minute: 40))!,
                sunlightExposureDuration: 25.0,
                isSPFApplied: true
            ),

            // 7월 20일 (현재 테스트 날짜) - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 20, hour: 9, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 20, hour: 9, minute: 20))!,
                sunlightExposureDuration: 20.0,
                isSPFApplied: true
            ),
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 20, hour: 13, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 20, hour: 13, minute: 25))!,
                sunlightExposureDuration: 25.0,
                isSPFApplied: true
            ),
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 20, hour: 17, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 20, hour: 17, minute: 15))!,
                sunlightExposureDuration: 15.0,
                isSPFApplied: false
            ),

            // 7월 21일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 21, hour: 11, minute: 30))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 21, hour: 11, minute: 50))!,
                sunlightExposureDuration: 20.0,
                isSPFApplied: true
            ),

            // 7월 22일 - 기록 없음

            // 7월 23일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 23, hour: 12, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 23, hour: 12, minute: 35))!,
                sunlightExposureDuration: 35.0,
                isSPFApplied: false
            ),

            // 7월 24일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 24, hour: 8, minute: 45))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 24, hour: 9, minute: 0))!,
                sunlightExposureDuration: 15.0,
                isSPFApplied: true
            ),
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 24, hour: 16, minute: 30))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 24, hour: 16, minute: 45))!,
                sunlightExposureDuration: 15.0,
                isSPFApplied: false
            ),

            // 7월 25일 - 기록 없음

            // 7월 26일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 26, hour: 10, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 26, hour: 10, minute: 30))!,
                sunlightExposureDuration: 30.0,
                isSPFApplied: true
            ),

            // 7월 27일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 27, hour: 14, minute: 15))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 27, hour: 14, minute: 40))!,
                sunlightExposureDuration: 25.0,
                isSPFApplied: false
            ),

            // 7월 28일 - 기록 없음

            // 7월 29일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 29, hour: 9, minute: 30))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 29, hour: 9, minute: 50))!,
                sunlightExposureDuration: 20.0,
                isSPFApplied: true
            ),
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 29, hour: 15, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 29, hour: 15, minute: 20))!,
                sunlightExposureDuration: 20.0,
                isSPFApplied: true
            ),

            // 7월 30일 - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 30, hour: 11, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 30, hour: 11, minute: 15))!,
                sunlightExposureDuration: 15.0,
                isSPFApplied: false
            ),
            UVExposeRecord(
                startDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 30, hour: 16, minute: 0))!,
                endDate: calendar.date(from: DateComponents(year: 2025, month: 7, day: 30, hour: 16, minute: 25))!,
                sunlightExposureDuration: 25.0,
                isSPFApplied: true
            )
        ]
    }
}
