//
//  MockUVExposureRepository.swift
//  TarTanning
//
//  Created by Jun on 7/20/25.
//

import Foundation

class MockUVExposureRepository: UVExposureRepository {
    private var dailyExposureStore: [DailyUVExpose] = []
    
    func getTodayUVExposure() async throws -> DailyUVExpose {
        let today = Date()
        
        if let existingData = dailyExposureStore.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }) {
            return existingData
        }
        
        let dailyExposure = try await createDailyUVExposureFromRecords(for: today)
        
        dailyExposureStore.append(dailyExposure)
        
        return dailyExposure
    }
    
    func getWeeklyUVExposure() async throws -> [DailyUVExpose] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [DailyUVExpose] = []

        for dayOffset in 1...7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
   
            if let existingData = dailyExposureStore.first(where: {
                calendar.isDate($0.date, inSameDayAs: date)
            }) {
                weeklyData.append(existingData)
            } else {
                let dailyExposure = try await createDailyUVExposureFromRecords(for: date)
                dailyExposureStore.append(dailyExposure)
                weeklyData.append(dailyExposure)
            }
        }

        return weeklyData.reversed()
    }
    
    func getTodayUVProgressRate(userSkinType: SkinType) async throws -> Double {
        let todayExposure = try await getTodayUVExposure()
        let maxMED = userSkinType.maxMED
        
        print("🔍 DEBUG: todayExposure.totalUVDose = \(todayExposure.totalUVDose)")
        print("�� DEBUG: maxMED = \(maxMED)")

        guard maxMED > 0 else { return 0.0 }

        let progressRate = todayExposure.totalUVDose / maxMED
        print("🔍 DEBUG: progressRate = \(progressRate)")
        
        return progressRate
    }
    
    func getWeeklyUVProgressRates(userSkinType: SkinType) async throws -> [Double] {
        let weeklyExposure = try await getWeeklyUVExposure()
        let maxMED = userSkinType.maxMED

        return weeklyExposure.map { daily in
            guard maxMED > 0 else { return 0.0 }
            return daily.totalUVDose / maxMED
        }
    }
    
    func saveDailyUVExposure(_ dailyExposure: DailyUVExpose) async throws {
        dailyExposureStore.removeAll {
            Calendar.current.isDate($0.date, inSameDayAs: dailyExposure.date)
        }
        dailyExposureStore.append(dailyExposure)
    }
    
    func getDailyUVExposure(for date: Date) async throws -> DailyUVExpose? {
        return dailyExposureStore.first {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func updateDailyUVExposure(for date: Date) async throws {
        dailyExposureStore.removeAll {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
        
        let dailyExposure = try await createDailyUVExposureFromRecords(for: date)
        dailyExposureStore.append(dailyExposure)
    }
    
    private func createDailyUVExposureFromRecords(for date: Date) async throws -> DailyUVExpose {
        let dailyExposure = DailyUVExpose(date: date)
        
//        let dayRecords = UVExposeRecord.mockExposureRecords.filter {
//            Calendar.current.isDate($0.startDate, inSameDayAs: date)
//        }
//        
//        dailyExposure.exposureRecords = dayRecords
//        dailyExposure.totalSunlightMinutes = dayRecords.reduce(0) {
//            $0 + $1.sunlightExposureDuration
//        }
//        
//        let sunScreenInfo = SunScreenInfo.mockSunscreen
//        var totalUVDose: Double = 0.0
//        
//        for record in dayRecords {
//            let recordHour = Calendar.current.component(.hour, from: record.startDate)
//            let recordUVIndex = HourlyWeather.mockHourlyWeather.first { $0.hour == recordHour }?.uvIndex ?? 0.0
//            
//            let spfValue = record.isSPFApplied ? Double(sunScreenInfo.spfIndex) : nil
//            let uvDose = MEDCalculator.calculateUVDose(
//                uvIndex: recordUVIndex,
//                durationMinutes: record.sunlightExposureDuration,
//                spf: spfValue
//            )
//            record.uvDose = uvDose
//            totalUVDose += uvDose
//        }
//        
//        dailyExposure.totalUVDose = totalUVDose
        
        return dailyExposure
    }
}
