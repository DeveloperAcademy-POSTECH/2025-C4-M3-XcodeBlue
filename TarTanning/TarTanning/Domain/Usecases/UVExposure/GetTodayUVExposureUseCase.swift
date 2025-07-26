//
//  GetTodayUVExposureUseCase.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

import Foundation
import SwiftData

@MainActor
/**
 목적: 오늘의 UV 노출량 데이터 조회
 입력: 없음
 출력: DailyUVExpose, UVExposeRecord 배열
 비즈니스 로직:
 - SwiftData에서 오늘 날짜의 DailyUVExpose 조회
 - UVExposeRecord들의 총합 계산
 - UV Dose 정보 포함
 */

final class GetTodayUVExposureUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// 오늘의 DailyUVExpose 데이터 조회
    func getTodayDailyUVExposure() async throws -> DailyUVExpose? {
        print("📊 [GetTodayUVExposureUseCase] Fetching today's UV exposure data")
        
        let today = Calendar.current.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<DailyUVExpose>()
        let allDailyData = try modelContext.fetch(descriptor)
        
        let todayData = allDailyData.first { daily in
            Calendar.current.isDate(daily.date, inSameDayAs: today)
        }
        
        if let todayData = todayData {
            print("✅ [GetTodayUVExposureUseCase] Found today's data: \(todayData.totalSunlightMinutes) minutes, \(String(format: "%.2f", todayData.totalUVDose)) UV dose")
        } else {
            print("📭 [GetTodayUVExposureUseCase] No data found for today")
        }
        
        return todayData
    }
    
    /// 오늘의 총 일광시간 조회
    func getTotalSunlightMinutes(from dailyUV: DailyUVExpose?) -> Double {
        guard let dailyUV = dailyUV else { return 0.0 }
        return dailyUV.totalSunlightMinutes
    }
    
    /// 오늘의 총 UV Dose 조회
    func getTotalUVDose(from dailyUV: DailyUVExpose?) -> Double {
        guard let dailyUV = dailyUV else { return 0.0 }
        return dailyUV.totalUVDose
    }
    
    /// 오늘의 UV 노출 기록들 조회
    func getTodayUVExposeRecords() async throws -> [UVExposeRecord] {
        print("📊 [GetTodayUVExposureUseCase] Fetching today's UV expose records")
        
        let today = Calendar.current.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<UVExposeRecord>()
        let allRecords = try modelContext.fetch(descriptor)
        
        let todayRecords = allRecords.filter { record in
            Calendar.current.isDate(record.startDate, inSameDayAs: today)
        }.sorted { $0.startDate < $1.startDate }
        
        print("✅ [GetTodayUVExposureUseCase] Found \(todayRecords.count) records for today")
        return todayRecords
    }
    
    /// 오늘의 UV 노출 요약 정보 조회
    func getTodayUVExposureSummary() async throws -> UVExposureSummary {
        let todayData = try await getTodayDailyUVExposure()
        let todayRecords = try await getTodayUVExposeRecords()
        
        let totalMinutes = getTotalSunlightMinutes(from: todayData)
        let totalUVDose = getTotalUVDose(from: todayData)
        let recordCount = todayRecords.count
        let averageSessionMinutes = recordCount > 0 ? totalMinutes / Double(recordCount) : 0.0
        
        return UVExposureSummary(
            totalSunlightMinutes: totalMinutes,
            totalUVDose: totalUVDose,
            recordCount: recordCount,
            averageSessionMinutes: averageSessionMinutes,
            dailyUVExpose: todayData
        )
    }
    
    /// 오늘의 UV 노출 통계 조회
    func getTodayUVExposureStatistics() async throws -> UVExposureStatistics {
        let todayRecords = try await getTodayUVExposeRecords()
        
        let totalMinutes = todayRecords.reduce(0) { $0 + $1.sunlightExposureDuration }
        let totalUVDose = todayRecords.reduce(0) { $0 + $1.uvDose }
        
        let averageMinutes = todayRecords.isEmpty ? 0 : totalMinutes / Double(todayRecords.count)
        let averageUVDose = todayRecords.isEmpty ? 0 : totalUVDose / Double(todayRecords.count)
        
        let maxMinutes = todayRecords.map { $0.sunlightExposureDuration }.max() ?? 0
        let maxUVDose = todayRecords.map { $0.uvDose }.max() ?? 0
        
        return UVExposureStatistics(
            totalRecords: todayRecords.count,
            totalMinutes: totalMinutes,
            totalUVDose: totalUVDose,
            averageMinutes: averageMinutes,
            averageUVDose: averageUVDose,
            maxMinutes: maxMinutes,
            maxUVDose: maxUVDose
        )
    }
}

// MARK: - Supporting Types

struct UVExposureSummary {
    let totalSunlightMinutes: Double
    let totalUVDose: Double
    let recordCount: Int
    let averageSessionMinutes: Double
    let dailyUVExpose: DailyUVExpose?
}

struct UVExposureStatistics {
    let totalRecords: Int
    let totalMinutes: Double
    let totalUVDose: Double
    let averageMinutes: Double
    let averageUVDose: Double
    let maxMinutes: Double
    let maxUVDose: Double
}
