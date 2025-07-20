//
//  MockUVExposureRepository.swift
//  TarTanning
//
//  Created by Jun on 7/20/25.
//

import Foundation

class MockUVExposureRepository: UVExposureRepository {
    // ✅ DailyUVExpose 저장소 (SwiftData 대신)
    private var dailyExposureStore: [DailyUVExpose] = []
    
    // MARK: - Dashboard 핵심 메서드들
    func getTodayUVExposure() async throws -> DailyUVExpose {
        let today = Date()
        
        // ✅ 저장소에서 오늘 날짜 데이터가 있는지 확인
        if let existingData = dailyExposureStore.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }) {
            return existingData
        }
        
        // ✅ 저장소에 데이터가 없으면 UVExposeRecord에서 계산해서 DailyUVExpose 생성
        let dailyExposure = try await createDailyUVExposureFromRecords(for: today)
        
        // ✅ 저장소에 저장
        dailyExposureStore.append(dailyExposure)
        
        return dailyExposure
    }
    
    func getWeeklyUVExposure() async throws -> [DailyUVExpose] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [DailyUVExpose] = []

        // ✅ 최근 7일 데이터 조회
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            
            // ✅ 저장소에서 데이터가 있는지 확인
            if let existingData = dailyExposureStore.first(where: {
                calendar.isDate($0.date, inSameDayAs: date)
            }) {
                weeklyData.append(existingData)
            } else {
                // ✅ 저장소에 데이터가 없으면 UVExposeRecord에서 계산해서 DailyUVExpose 생성
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
    
    // MARK: - DailyUVExpose 관리 메서드들
    
    func saveDailyUVExposure(_ dailyExposure: DailyUVExpose) async throws {
        // 기존 데이터가 있으면 제거
        dailyExposureStore.removeAll {
            Calendar.current.isDate($0.date, inSameDayAs: dailyExposure.date)
        }
        // 새 데이터 저장
        dailyExposureStore.append(dailyExposure)
    }
    
    func getDailyUVExposure(for date: Date) async throws -> DailyUVExpose? {
        return dailyExposureStore.first {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func updateDailyUVExposure(for date: Date) async throws {
        // 해당 날짜의 기존 데이터 제거
        dailyExposureStore.removeAll {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
        
        // 새로운 DailyUVExpose 생성하여 저장
        let dailyExposure = try await createDailyUVExposureFromRecords(for: date)
        dailyExposureStore.append(dailyExposure)
    }
    
    // MARK: - 헬퍼 메서드
    
    // ✅ UVExposeRecord에서 DailyUVExpose 생성하는 핵심 로직
    private func createDailyUVExposureFromRecords(for date: Date) async throws -> DailyUVExpose {
        let dailyExposure = DailyUVExpose(date: date)
        
        // ✅ 해당 날짜의 UVExposeRecord들 필터링 (HealthKit 데이터와 동일한 방식)
        let dayRecords = UVExposeRecord.mockExposureRecords.filter {
            Calendar.current.isDate($0.startDate, inSameDayAs: date)
        }
        
        // ✅ DailyUVExpose에 데이터 설정
        dailyExposure.exposureRecords = dayRecords
        dailyExposure.totalSunlightMinutes = dayRecords.reduce(0) {
            $0 + $1.sunlightExposureDuration
        }
        
        // ✅ UV Dose 계산
        let sunScreenInfo = SunScreenInfo.mockSunscreen
        var totalUVDose: Double = 0.0
        
        for record in dayRecords {
            let recordHour = Calendar.current.component(.hour, from: record.startDate)
            let recordUVIndex = HourlyWeather.mockHourlyWeather.first { $0.hour == recordHour }?.uvIndex ?? 0.0
            
            let spfValue = record.isSPFApplied ? Double(sunScreenInfo.spfIndex) : nil
            let uvDose = MEDCalculator.calculateUVDose(
                uvIndex: recordUVIndex,
                durationMinutes: record.sunlightExposureDuration,
                spf: spfValue
            )
            record.uvDose = uvDose
            totalUVDose += uvDose
        }
        
        dailyExposure.totalUVDose = totalUVDose
        
        return dailyExposure
    }
}
