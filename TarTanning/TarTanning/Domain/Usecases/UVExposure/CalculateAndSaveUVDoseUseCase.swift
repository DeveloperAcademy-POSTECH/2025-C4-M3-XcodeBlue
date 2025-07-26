//
//  CalculateAndSaveUVDoseUseCase.swift
//  TarTanning
//
//  Created by Jun on 7/26/25.
//

import Foundation
import SwiftData

@MainActor
/**
 목적: UVExposeRecord의 UV Dose 계산 및 저장
 입력: 날짜, UV 지수 데이터
 출력: 계산된 UV Dose
 비즈니스 로직:
 - 해당 날짜의 UVExposeRecord 조회
 - 각 기록의 시간대에 맞는 UV 지수 적용
 - MEDCalculator로 UV Dose 계산
 - DailyUVExpose의 totalUVDose 업데이트
 */

final class CalculateAndSaveUVDoseUseCase {
    private let modelContext: ModelContext
    private let getUserProfileUseCase = GetUserProfileUseCase()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// 오늘의 UV Dose 계산 및 저장
    func calculateAndSaveTodayUVDose(uvIndexData: [Int: Double]) async throws {
        print("🧮 [CalculateAndSaveUVDoseUseCase] Calculating today's UV dose")
        
        let today = Calendar.current.startOfDay(for: Date())
        
        // 1. 오늘의 UVExposeRecord 조회
        let todayRecords = try await getTodayUVExposeRecords()
        
        if todayRecords.isEmpty {
            print("📭 [CalculateAndSaveUVDoseUseCase] No UV records found for today")
            return
        }
        
        // 2. 각 기록에 대해 UV Dose 계산
        var totalUVDose: Double = 0.0
        
        for record in todayRecords {
            let uvDose = try await calculateUVDoseForRecord(record, uvIndexData: uvIndexData)
            record.uvDose = uvDose
            totalUVDose += uvDose
            
            print("📊 [CalculateAndSaveUVDoseUseCase] Record UV dose: \(String(format: "%.2f", uvDose))")
        }
        
        // 3. DailyUVExpose의 totalUVDose 업데이트
        if let dailyUV = try await getTodayDailyUVExpose() {
            dailyUV.totalUVDose = totalUVDose
            print("📊 [CalculateAndSaveUVDoseUseCase] Total UV dose: \(String(format: "%.2f", totalUVDose))")
        }
        
        try modelContext.save()
        print("✅ [CalculateAndSaveUVDoseUseCase] UV dose calculation completed")
    }
    
    /// 특정 날짜의 UV Dose 계산 및 저장
    func calculateAndSaveUVDose(for date: Date, uvIndexData: [Int: Double]) async throws {
        print("🧮 [CalculateAndSaveUVDoseUseCase] Calculating UV dose for \(date)")
        
        // 1. 해당 날짜의 UVExposeRecord 조회
        let dateRecords = try await getUVExposeRecords(for: date)
        
        if dateRecords.isEmpty {
            print("📭 [CalculateAndSaveUVDoseUseCase] No UV records found for \(date)")
            return
        }
        
        // 2. 각 기록에 대해 UV Dose 계산
        var totalUVDose: Double = 0.0
        
        for record in dateRecords {
            let uvDose = try await calculateUVDoseForRecord(record, uvIndexData: uvIndexData)
            record.uvDose = uvDose
            totalUVDose += uvDose
        }
        
        // 3. DailyUVExpose의 totalUVDose 업데이트
        if let dailyUV = try await getDailyUVExpose(for: date) {
            dailyUV.totalUVDose = totalUVDose
        }
        
        try modelContext.save()
        print("✅ [CalculateAndSaveUVDoseUseCase] UV dose calculation completed for \(date)")
    }
    
    // MARK: - Private Methods
    
    /// 오늘의 UVExposeRecord 조회
    private func getTodayUVExposeRecords() async throws -> [UVExposeRecord] {
        let today = Calendar.current.startOfDay(for: Date())
        return try await getUVExposeRecords(for: today)
    }
    
    /// 특정 날짜의 UVExposeRecord 조회
    private func getUVExposeRecords(for date: Date) async throws -> [UVExposeRecord] {
        let descriptor = FetchDescriptor<UVExposeRecord>()
        let allRecords = try modelContext.fetch(descriptor)
        
        let dateRecords = allRecords.filter { record in
            Calendar.current.isDate(record.startDate, inSameDayAs: date)
        }
        
        return dateRecords
    }
    
    /// 오늘의 DailyUVExpose 조회
    private func getTodayDailyUVExpose() async throws -> DailyUVExpose? {
        let today = Calendar.current.startOfDay(for: Date())
        return try await getDailyUVExpose(for: today)
    }
    
    /// 특정 날짜의 DailyUVExpose 조회
    private func getDailyUVExpose(for date: Date) async throws -> DailyUVExpose? {
        let descriptor = FetchDescriptor<DailyUVExpose>()
        let allDailyData = try modelContext.fetch(descriptor)
        
        let dailyUV = allDailyData.first { daily in
            Calendar.current.isDate(daily.date, inSameDayAs: date)
        }
        
        return dailyUV
    }
    
    /// 개별 UVExposeRecord의 UV Dose 계산
    private func calculateUVDoseForRecord(_ record: UVExposeRecord, uvIndexData: [Int: Double]) async throws -> Double {
        // 1. 기록의 시작 시간에서 시간대 추출
        let startHour = Calendar.current.component(.hour, from: record.startDate)
        
        // 2. 해당 시간대의 UV 지수 가져오기
        let uvIndex = uvIndexData[startHour] ?? 0.0
        
        // 3. 사용자 프로필에서 SPF 정보 가져오기 (현재는 사용하지 않음)
        let profile = getUserProfileUseCase.getUserProfile()
        let spfValue: Double? = nil // 현재는 SPF 적용 안함
        
        // 4. MEDCalculator로 UV Dose 계산
        let uvDose = MEDCalculator.calculateUVDose(
            uvIndex: uvIndex,
            durationMinutes: record.sunlightExposureDuration,
            spf: spfValue
        )
        
        return uvDose
    }
} 