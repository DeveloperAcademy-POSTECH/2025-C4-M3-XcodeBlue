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
    static var mockTodayExposureRecords: [UVExposeRecord] {
        let today = Date()
        let calendar = Calendar.current

        return [
            // 오전 산책 (9:30-10:15) - SPF 30 적용
            UVExposeRecord(
                startDate: calendar.date(
                    bySettingHour: 9,
                    minute: 30,
                    second: 0,
                    of: today
                )!,
                endDate: calendar.date(
                    bySettingHour: 10,
                    minute: 15,
                    second: 0,
                    of: today
                )!,
                sunlightExposureDuration: 45.0,  // HealthKit 일광시간
                uvDose: MEDCalculator.calculateUVDose(
                    uvIndex: 4.5,  // 9-10시 평균 UV지수
                    durationMinutes: 45.0,
                    spf: 30.0  // SPF 30 적용
                )
            ),

            // 점심시간 외출 (12:00-13:30) - SPF 30 적용
            UVExposeRecord(
                startDate: calendar.date(
                    bySettingHour: 12,
                    minute: 0,
                    second: 0,
                    of: today
                )!,
                endDate: calendar.date(
                    bySettingHour: 13,
                    minute: 30,
                    second: 0,
                    of: today
                )!,
                sunlightExposureDuration: 90.0,  // HealthKit 일광시간
                uvDose: MEDCalculator.calculateUVDose(
                    uvIndex: 8.5,  // 12-13시 평균 UV지수
                    durationMinutes: 90.0,
                    spf: 30.0  // SPF 30 적용
                )
            ),

            // 오후 산책 (16:00-16:45) - SPF 미적용
            UVExposeRecord(
                startDate: calendar.date(
                    bySettingHour: 16,
                    minute: 0,
                    second: 0,
                    of: today
                )!,
                endDate: calendar.date(
                    bySettingHour: 16,
                    minute: 45,
                    second: 0,
                    of: today
                )!,
                sunlightExposureDuration: 45.0,  // HealthKit 일광시간
                uvDose: MEDCalculator.calculateUVDose(
                    uvIndex: 4.2,  // 16-17시 평균 UV지수
                    durationMinutes: 45.0,
                    spf: nil  // SPF 미적용
                )
            ),
        ]
    }
}
