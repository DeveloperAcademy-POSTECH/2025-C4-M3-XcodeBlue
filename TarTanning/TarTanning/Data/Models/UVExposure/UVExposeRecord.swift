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
    /// 일광 시간 기록들 Mock 데이터 (여러 날짜 포함)
    static var mockExposureRecords: [UVExposeRecord] {
        let calendar = Calendar.current
        let today = Date()

        return [
            // 오늘 (7월 1일) - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(
                    bySettingHour: 9,
                    minute: 30,
                    second: 0,
                    of: today
                )!,
                endDate: calendar.date(
                    bySettingHour: 9,
                    minute: 35,
                    second: 0,
                    of: today
                )!,
                sunlightExposureDuration: 5.0,
                isSPFApplied: true
            ),
            UVExposeRecord(
                startDate: calendar.date(
                    bySettingHour: 12,
                    minute: 0,
                    second: 0,
                    of: today
                )!,
                endDate: calendar.date(
                    bySettingHour: 12,
                    minute: 15,
                    second: 0,
                    of: today
                )!,
                sunlightExposureDuration: 15.0,
                isSPFApplied: true
            ),
            UVExposeRecord(
                startDate: calendar.date(
                    bySettingHour: 16,
                    minute: 0,
                    second: 0,
                    of: today
                )!,
                endDate: calendar.date(
                    bySettingHour: 16,
                    minute: 10,
                    second: 0,
                    of: today
                )!,
                sunlightExposureDuration: 10.0,
                isSPFApplied: false
            ),

            // 어제 (6월 30일) - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(
                    bySettingHour: 10,
                    minute: 0,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -1, to: today)!
                )!,
                endDate: calendar.date(
                    bySettingHour: 10,
                    minute: 8,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -1, to: today)!
                )!,
                sunlightExposureDuration: 8.0,
                isSPFApplied: true
            ),
            UVExposeRecord(
                startDate: calendar.date(
                    bySettingHour: 14,
                    minute: 30,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -1, to: today)!
                )!,
                endDate: calendar.date(
                    bySettingHour: 15,
                    minute: 20,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -1, to: today)!
                )!,
                sunlightExposureDuration: 50.0,
                isSPFApplied: true
            ),

            // 2일 전 (6월 29일) - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(
                    bySettingHour: 11,
                    minute: 0,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -2, to: today)!
                )!,
                endDate: calendar.date(
                    bySettingHour: 11,
                    minute: 25,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -2, to: today)!
                )!,
                sunlightExposureDuration: 25.0,
                isSPFApplied: false
            ),
            UVExposeRecord(
                startDate: calendar.date(
                    bySettingHour: 16,
                    minute: 0,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -2, to: today)!
                )!,
                endDate: calendar.date(
                    bySettingHour: 16,
                    minute: 30,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -2, to: today)!
                )!,
                sunlightExposureDuration: 30.0,
                isSPFApplied: false
            ),

            // 3일 전 (6월 28일) - 기록 없음

            // 4일 전 (6월 27일) - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(
                    bySettingHour: 9,
                    minute: 45,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -4, to: today)!
                )!,
                endDate: calendar.date(
                    bySettingHour: 9,
                    minute: 50,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -4, to: today)!
                )!,
                sunlightExposureDuration: 5.0,
                isSPFApplied: true
            ),

            // 5일 전 (6월 26일) - 기록 없음

            // 6일 전 (6월 25일) - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(
                    bySettingHour: 13,
                    minute: 15,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -6, to: today)!
                )!,
                endDate: calendar.date(
                    bySettingHour: 13,
                    minute: 35,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -6, to: today)!
                )!,
                sunlightExposureDuration: 20.0,
                isSPFApplied: true
            ),

            // 7일 전 (6월 24일) - 여러 개 세션
            UVExposeRecord(
                startDate: calendar.date(
                    bySettingHour: 14,
                    minute: 0,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -7, to: today)!
                )!,
                endDate: calendar.date(
                    bySettingHour: 14,
                    minute: 2,
                    second: 0,
                    of: calendar.date(byAdding: .day, value: -7, to: today)!
                )!,
                sunlightExposureDuration: 2.0,
                isSPFApplied: false
            )
        ]
    }
}
