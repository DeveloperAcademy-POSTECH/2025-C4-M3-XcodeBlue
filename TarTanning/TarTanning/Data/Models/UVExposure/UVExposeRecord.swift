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
    /// 일광 시간 기록들 Mock 데이터 (최근 7일 기준)
    static var mockExposureRecords: [UVExposeRecord] {
        let calendar = Calendar.current
        let today = Date()

        var allRecords: [UVExposeRecord] = []

        // 최근 7일 데이터 생성 (오늘 포함)
        for dayOffset in 0..<7 {
            let targetDate = calendar.date(
                byAdding: .day,
                value: -dayOffset,
                to: today
            )!
            let targetYear = calendar.component(.year, from: targetDate)
            let targetMonth = calendar.component(.month, from: targetDate)
            let targetDay = calendar.component(.day, from: targetDate)

            // 각 날짜별 데이터
            let dayRecords:
                [(hour: Int, duration: Double, isSPFApplied: Bool)] =
                    dayOffset == 0
                    ? [
                        // 오늘 (7월 20일) - 기존 데이터
                        (9, 20.0, true),
                        (13, 30.0, true),
                        (17, 55.0, false),
                    ]
                    : dayOffset == 1
                        ? [
                            // 어제 (7월 19일) - 여러 개 세션
                            (8, 30.0, true),
                            (11, 45.0, true),
                            (15, 20.0, false),
                            (18, 35.0, true),
                        ]
                        : dayOffset == 2
                            ? [
                                // 2일 전 (7월 18일)
                                (10, 40.0, true),
                                (14, 25.0, false),
                                (16, 30.0, true),
                            ]
                            : dayOffset == 3
                                ? [
                                    // 3일 전 (7월 17일)
                                    (9, 35.0, true),
                                    (12, 50.0, true),
                                    (17, 15.0, false),
                                ]
                                : dayOffset == 4
                                    ? [
                                        // 4일 전 (7월 16일)
                                        (11, 25.0, false),
                                        (13, 40.0, true),
                                        (15, 30.0, true),
                                    ]
                                    : dayOffset == 5
                                        ? [
                                            // 5일 전 (7월 15일)
                                            (8, 45.0, true),
                                            (10, 20.0, true),
                                            (14, 35.0, false),
                                            (16, 25.0, true),
                                        ]
                                        : [
                                            // 6일 전 (7월 14일)
                                            (9, 30.0, true),
                                            (12, 40.0, true),
                                            (15, 20.0, false),
                                        ]

            for (hour, duration, isSPFApplied) in dayRecords {
                let startDate = calendar.date(
                    from: DateComponents(
                        year: targetYear,
                        month: targetMonth,
                        day: targetDay,
                        hour: hour,
                        minute: 0
                    )
                )!
                let endDate = calendar.date(
                    byAdding: .minute,
                    value: Int(duration),
                    to: startDate
                )!

                allRecords.append(
                    UVExposeRecord(
                        startDate: startDate,
                        endDate: endDate,
                        sunlightExposureDuration: duration,
                        isSPFApplied: isSPFApplied
                    )
                )
            }
        }

        return allRecords
    }
}

