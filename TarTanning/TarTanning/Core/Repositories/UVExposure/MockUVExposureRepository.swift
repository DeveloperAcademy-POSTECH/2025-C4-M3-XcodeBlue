//
//  MockUVExposureRepository.swift
//  TarTanning
//
//  Created by Jun on 7/20/25.
//

import Foundation

class MockUVExposureRepository: UVExposureRepository {
    func getTodayUVExposure() async throws -> DailyUVExpose {
        let today = Date()
        let dailyExposure = DailyUVExpose(date: today)
        
        // 오늘 날짜의 UVExposeRecord들만 필터링
        let todayRecords = UVExposeRecord.mockExposureRecords.filter {
            Calendar.current.isDate($0.startDate, inSameDayAs: today)
        }
        
        for record in todayRecords {
            print("🔍 DEBUG: record startDate = \(record.startDate), duration = \(record.sunlightExposureDuration)")
        }
        
        dailyExposure.exposureRecords = todayRecords
        dailyExposure.totalSunlightMinutes = todayRecords.reduce(0) {
            $0 + $1.sunlightExposureDuration
        }
        
        print("🔍 DEBUG: totalSunlightMinutes = \(dailyExposure.totalSunlightMinutes)")
        
        var totalUVDose: Double = 0.0
        for record in todayRecords {
            let recordHour = Calendar.current.component(.hour, from: record.startDate)
            let recordUVIndex = HourlyWeather.mockHourlyWeather.first { $0.hour == recordHour }?.uvIndex ?? 0.0
            
            print("🔍 DEBUG: recordHour = \(recordHour), recordUVIndex = \(recordUVIndex)")
            
            let spfValue = record.isSPFApplied ? 30.0 : nil
            let uvDose = MEDCalculator.calculateUVDose(
                uvIndex: recordUVIndex,
                durationMinutes: record.sunlightExposureDuration,
                spf: spfValue
            )
            record.uvDose = uvDose
            totalUVDose += uvDose
            
            print("🔍 DEBUG: uvDose = \(uvDose), totalUVDose = \(totalUVDose)")
        }
        
        dailyExposure.totalUVDose = totalUVDose
        print("🔍 DEBUG: final totalUVDose = \(totalUVDose)")
        
        return dailyExposure
    }

    func getTodayUVProgressRate(userSkinType: SkinType) async throws -> Double {
        let todayExposure = try await getTodayUVExposure()
        let maxMED = userSkinType.maxMED
        
        print("DEBUG: todayExposure.totalUVDose = \(todayExposure.totalUVDose)")
        print("DEBUG: maxMED = \(maxMED)")

        guard maxMED > 0 else { return 0.0 }

        let progressRate = todayExposure.totalUVDose / maxMED
        print("DEBUG: progressRate = \(progressRate)")
        
        return progressRate
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
            
            var totalUVDose: Double = 0.0
            for record in dayRecords {
                let recordHour = Calendar.current.component(.hour, from: record.startDate)
                let recordUVIndex = HourlyWeather.mockHourlyWeather.first { $0.hour == recordHour }?.uvIndex ?? 0.0
                
                let spfValue = record.isSPFApplied ? 30.0 : nil
                let uvDose = MEDCalculator.calculateUVDose(
                    uvIndex: recordUVIndex,
                    durationMinutes: record.sunlightExposureDuration,
                    spf: spfValue
                )
                record.uvDose = uvDose
                totalUVDose += uvDose
            }
            dailyExposure.totalUVDose = totalUVDose

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

        let isSunScreenActive =
            currentTime.timeIntervalSince(sunScreenInfo.activationTime)
            < SunScreenInfo.duration

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
