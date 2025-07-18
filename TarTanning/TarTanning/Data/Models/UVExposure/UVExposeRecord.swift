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
    var startDate: Date  // 일광 노출이 시작된 시간 (11:42)
    var endDate: Date  // 일광 노출이 종료된 시간 (12:15)
    var sunlightExposureDuration: Double  // startDate ~ endDate 사이의 일광 시간
    var uvDose: Double  // start Date ~ endDate 시간 사이의 UV 누적량 (UV노출량 식 계산, 단위 J/m^2)
    var spfIndex: Int?  // 해당 세션에서 사용한 SPF
    var dailyExposure: DailyUVExpose?  // 관계 설정

    init(
        startDate: Date,
        endDate: Date,
        sunlightExposureDuration: Double,
        uvDose: Double
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.sunlightExposureDuration = sunlightExposureDuration
        self.uvDose = uvDose
        self.spfIndex = nil
        self.dailyExposure = nil
    }
}

extension UVExposeRecord {
    /// 오늘 UV 노출 기록 Mock 데이터
    static var mockTodayUVExposeRecord: UVExposeRecord {
        let today = Date()
        let calendar = Calendar.current
        let startTime = calendar.date(
            bySettingHour: 10,
            minute: 30,
            second: 0,
            of: today
        )!
        let endTime = calendar.date(
            bySettingHour: 12,
            minute: 15,
            second: 0,
            of: today
        )!

        return UVExposeRecord(
            startDate: startTime,
            endDate: endTime,
            sunlightExposureDuration: 105.0,  // 1시간 45분
            uvDose: 450.0  // J/m^2 단위
        )
    }

    /// 차트용 7일치 UV 노출 기록 (오늘 제외, 7일 전부터 어제까지)
    static var mockWeeklyChartUVExposeRecords: [UVExposeRecord] {
        let calendar = Calendar.current
        let today = Date()

        return [
            // 7일 전 (일요일)
            UVExposeRecord(
                startDate: calendar.date(byAdding: .day, value: -7, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -7, to: today)!,
                sunlightExposureDuration: 45.0,  // 45분
                uvDose: 180.0
            ),

            // 6일 전 (월요일)
            UVExposeRecord(
                startDate: calendar.date(byAdding: .day, value: -6, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -6, to: today)!,
                sunlightExposureDuration: 0.0,  // 기록 없음
                uvDose: 0.0
            ),

            // 5일 전 (화요일)
            UVExposeRecord(
                startDate: calendar.date(byAdding: .day, value: -5, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -5, to: today)!,
                sunlightExposureDuration: 120.0,  // 2시간
                uvDose: 520.0
            ),

            // 4일 전 (수요일)
            UVExposeRecord(
                startDate: calendar.date(byAdding: .day, value: -4, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -4, to: today)!,
                sunlightExposureDuration: 0.0,  // 기록 없음
                uvDose: 0.0
            ),

            // 3일 전 (목요일)
            UVExposeRecord(
                startDate: calendar.date(byAdding: .day, value: -3, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -3, to: today)!,
                sunlightExposureDuration: 90.0,  // 1시간 30분
                uvDose: 380.0
            ),

            // 2일 전 (금요일)
            UVExposeRecord(
                startDate: calendar.date(byAdding: .day, value: -2, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -2, to: today)!,
                sunlightExposureDuration: 75.0,  // 1시간 15분
                uvDose: 320.0
            ),

            // 1일 전 (토요일)
            UVExposeRecord(
                startDate: calendar.date(byAdding: .day, value: -1, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -1, to: today)!,
                sunlightExposureDuration: 0.0,  // 기록 없음
                uvDose: 0.0
            ),
        ]
    }
}
