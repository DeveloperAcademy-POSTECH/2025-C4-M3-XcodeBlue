//
//  MockUVExposureRepository.swift
//  TarTanning
//
//  Created by Jun on 7/20/25.
//

import Foundation

class MockUVExposureRepository: UVExposureRepository {
    func getTodayUVExposure() async throws -> DailyUVExpose {
        return DailyUVExpose.mockTodayDailyExposure
    }

    func getWeeklyUVExposure() async throws -> [DailyUVExpose] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [DailyUVExpose] = []

        for dayOffset in 0..<7 {
            let date = calendar.date(
                byAdding: .day,
                value: -dayOffset,
                to: today
            )!
            let dailyExposure = DailyUVExpose(date: date)

            let dayRecords = UVExposeRecord.mockExposureRecords.filter {
                calendar.isDate($0.startDate, inSameDayAs: date)
            }

            dailyExposure.exposureRecords = dayRecords
            dailyExposure.totalSunlightMinutes = dayRecords.reduce(0) {
                $0 + $1.sunlightExposureDuration
            }
            dailyExposure.totalUVDose = dayRecords.reduce(0) { $0 + $1.uvDose }

            weeklyData.append(dailyExposure)
        }

        return weeklyData.reversed()
    }

    func calculateAndSaveUVDose(
        for record: UVExposeRecord,
        uvIndex: Double,
        userSkinType: SkinType
    ) async throws -> Double {
        let sunScreenInfo = SunScreenInfo.mockSunscreen
        let currentTime = Date()

        // 선크림 모드가 활성화되어 있는지 확인
        let isSunScreenActive =
            currentTime.timeIntervalSince(sunScreenInfo.activationTime)
            < SunScreenInfo.duration

        // 선크림 발랐고, 선크림 모드가 활성화되어 있으면 SPF 적용
        let spfValue =
            (record.isSPFApplied && isSunScreenActive)
            ? Double(sunScreenInfo.spfIndex) : nil

        let uvDose = MEDCalculator.calculateUVDose(
            uvIndex: uvIndex,
            durationMinutes: record.sunlightExposureDuration,
            spf: spfValue
        )

        return uvDose
    }

    func updateDailyUVExposure(for date: Date) async throws {

    }

    func getTodayUVProgressRate(userSkinType: SkinType) async throws -> Double {
        let todayExposure = try await getTodayUVExposure()
        let maxMED = userSkinType.maxMED

        guard maxMED > 0 else { return 0.0 }

        return todayExposure.totalUVDose / maxMED
    }

    func getWeeklyUVProgressRates(userSkinType: SkinType) async throws
        -> [Double] {
        let weeklyExposure = try await getWeeklyUVExposure()
        let maxMED = userSkinType.maxMED

        return weeklyExposure.map { daily in
            guard maxMED > 0 else { return 0.0 }
            return daily.totalUVDose / maxMED
        }
    }

    func saveUVExposureRecord(_ record: UVExposeRecord) async throws {

    }

    func getUVExposureRecords(for date: Date) async throws -> [UVExposeRecord] {
        let calendar = Calendar.current
        return UVExposeRecord.mockExposureRecords.filter {
            calendar.isDate($0.startDate, inSameDayAs: date)
        }
    }

}
