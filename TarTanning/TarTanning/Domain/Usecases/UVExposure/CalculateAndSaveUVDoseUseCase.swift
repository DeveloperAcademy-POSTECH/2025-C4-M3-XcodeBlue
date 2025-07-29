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
    
    /// 오늘의 UV Dose 계산 및 저장 (SwiftData에서 실제 UV 지수 사용)
    func calculateAndSaveTodayUVDose() async throws {
        print("🧮 [CalculateAndSaveUVDoseUseCase] Calculating today's UV dose from SwiftData")
        
        let today = Calendar.current.startOfDay(for: Date())
        
        // 1. 오늘의 UVExposeRecord 조회
        let todayRecords = try await getTodayUVExposeRecords()
        
        if todayRecords.isEmpty {
            print("📭 [CalculateAndSaveUVDoseUseCase] No UV records found for today")
            return
        }
        
        // 2. 각 기록에 대해 UV Dose 계산 (🔒 이미 계산된 기록은 재계산 금지!)
        var totalUVDose: Double = 0.0
        var newlyCalculatedCount = 0
        var protectedCount = 0
        
        // 선크림 모드 여부 넘김
        let hasSunscreen = SunscreenViewModel.shared.isActive
        
        for record in todayRecords {
            // 🔒 데이터 무결성 보장: 이미 계산된 기록은 절대 재계산하지 않음
            if record.uvDose > 0.0 {
                // 기존 계산된 값 보호
                totalUVDose += record.uvDose
                protectedCount += 1
                print("🔒 [CalculateAndSaveUVDoseUseCase] PROTECTED existing UV dose: \(String(format: "%.4f", record.uvDose)) (\(record.startDate.formatted(date: .omitted, time: .shortened)) - \(record.endDate.formatted(date: .omitted, time: .shortened)))")
            } else {
                // 새로운 기록만 SwiftData에서 실제 UV 지수로 계산
                record.isSPFApplied = hasSunscreen
                let uvDose = try await calculateUVDoseForRecord(record)
                record.uvDose = uvDose
                totalUVDose += uvDose
                newlyCalculatedCount += 1
                print("✨ [CalculateAndSaveUVDoseUseCase] NEWLY calculated UV dose: \(String(format: "%.4f", uvDose)) (\(record.startDate.formatted(date: .omitted, time: .shortened)) - \(record.endDate.formatted(date: .omitted, time: .shortened)))")
            }
        }
        
        print("📊 [CalculateAndSaveUVDoseUseCase] Summary - Protected: \(protectedCount), Newly calculated: \(newlyCalculatedCount), Total UV dose: \(String(format: "%.4f", totalUVDose))")
        
        // 3. DailyUVExpose의 totalUVDose 업데이트
        if let dailyUV = try await getTodayDailyUVExpose() {
            dailyUV.totalUVDose = totalUVDose
            print("📊 [CalculateAndSaveUVDoseUseCase] Total UV dose: \(String(format: "%.2f", totalUVDose))")
        }
        
        try modelContext.save()
        print("✅ [CalculateAndSaveUVDoseUseCase] UV dose calculation completed")
    }
    
    /// 특정 날짜의 UV Dose 계산 및 저장 (SwiftData에서 실제 UV 지수 사용)
    func calculateAndSaveUVDose(for date: Date) async throws {
        print("🧮 [CalculateAndSaveUVDoseUseCase] Calculating UV dose for \(date.formatted(date: .abbreviated, time: .omitted)) from SwiftData")
        
        // 1. 해당 날짜의 UVExposeRecord 조회
        let dateRecords = try await getUVExposeRecords(for: date)
        
        if dateRecords.isEmpty {
            print("📭 [CalculateAndSaveUVDoseUseCase] No UV records found for \(date.formatted(date: .abbreviated, time: .omitted))")
            return
        }
        
        // 2. 각 기록에 대해 UV Dose 계산 (🔒 이미 계산된 기록은 재계산 금지!)
        var totalUVDose: Double = 0.0
        var newlyCalculatedCount = 0
        var protectedCount = 0
        
        for record in dateRecords {
            // 🔒 데이터 무결성 보장: 이미 계산된 기록은 절대 재계산하지 않음
            if record.uvDose > 0.0 {
                // 기존 계산된 값 보호
                totalUVDose += record.uvDose
                protectedCount += 1
                print("🔒 [CalculateAndSaveUVDoseUseCase] PROTECTED existing UV dose: \(String(format: "%.4f", record.uvDose)) for \(date.formatted(date: .abbreviated, time: .omitted))")
            } else {
                // 새로운 기록만 SwiftData에서 실제 UV 지수로 계산
                let uvDose = try await calculateUVDoseForRecord(record)
                record.uvDose = uvDose
                totalUVDose += uvDose
                newlyCalculatedCount += 1
                print("✨ [CalculateAndSaveUVDoseUseCase] NEWLY calculated UV dose: \(String(format: "%.4f", uvDose)) for \(date.formatted(date: .abbreviated, time: .omitted))")
            }
        }
        
        print("📊 [CalculateAndSaveUVDoseUseCase] Summary for \(date.formatted(date: .abbreviated, time: .omitted)) - Protected: \(protectedCount), Newly calculated: \(newlyCalculatedCount)")
        
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
    
    /// 개별 UVExposeRecord의 UV Dose 계산 (SwiftData에서 실제 UV 지수 조회)
    private func calculateUVDoseForRecord(_ record: UVExposeRecord) async throws -> Double {
        // 1. 기록의 시작 시간에서 날짜와 시간대 추출
        let recordDate = record.startDate
        let startHour = Calendar.current.component(.hour, from: recordDate)
        let recordDay = Calendar.current.startOfDay(for: recordDate)
        
        print("🔍 [CalculateAndSaveUVDoseUseCase] Looking for UV index - Date: \(recordDay.formatted(date: .abbreviated, time: .omitted)), Hour: \(startHour)")
        
        // 2. SwiftData에서 해당 날짜+시간의 실제 UV 지수 조회
        let uvIndex = try await getUVIndexFromSwiftData(date: recordDay, hour: startHour)
        
        // 3. 사용자 프로필에서 SPF 정보 가져오기 (현재는 사용하지 않음)
        let profile = getUserProfileUseCase.getUserProfile()
        let spfValue: Double? = nil // 현재는 SPF 적용 안함
        
        // 4. MEDCalculator로 UV Dose 계산
        let uvDose = MEDCalculator.calculateUVDose(
            uvIndex: uvIndex,
            durationMinutes: record.sunlightExposureDuration,
            spf: spfValue
        )
        
        print("📊 [CalculateAndSaveUVDoseUseCase] UV calculation - Hour: \(startHour), UV Index: \(String(format: "%.2f", uvIndex)), Duration: \(String(format: "%.1f", record.sunlightExposureDuration))min, UV Dose: \(String(format: "%.4f", uvDose))")
        
        return uvDose
    }
    
    /// SwiftData에서 특정 날짜+시간의 UV 지수 조회
    private func getUVIndexFromSwiftData(date: Date, hour: Int) async throws -> Double {
        // 해당 날짜의 LocationWeather 조회
        let descriptor = FetchDescriptor<LocationWeather>()
        let allLocationWeathers = try modelContext.fetch(descriptor)
        
        // 해당 날짜의 날씨 데이터 찾기
        let targetLocationWeather = allLocationWeathers.first { locationWeather in
            Calendar.current.isDate(locationWeather.date, inSameDayAs: date)
        }
        
        guard let locationWeather = targetLocationWeather else {
            print("⚠️ [CalculateAndSaveUVDoseUseCase] No weather data found for \(date.formatted(date: .abbreviated, time: .omitted))")
            return 0.0
        }
        
        // 해당 시간대의 HourlyWeather 찾기
        let targetHourlyWeather = locationWeather.hourlyWeathers.first { hourlyWeather in
            hourlyWeather.hour == hour
        }
        
        guard let hourlyWeather = targetHourlyWeather else {
            print("⚠️ [CalculateAndSaveUVDoseUseCase] No hourly weather data found for hour \(hour) on \(date.formatted(date: .abbreviated, time: .omitted))")
            return 0.0
        }
        
        print("✅ [CalculateAndSaveUVDoseUseCase] Found UV index \(String(format: "%.2f", hourlyWeather.uvIndex)) for \(date.formatted(date: .abbreviated, time: .omitted)) at \(hour):00 in \(locationWeather.city)")
        
        return hourlyWeather.uvIndex
    }
} 
