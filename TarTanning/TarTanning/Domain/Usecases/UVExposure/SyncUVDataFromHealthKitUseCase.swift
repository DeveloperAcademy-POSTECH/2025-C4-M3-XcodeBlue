//
//  SyncUVDataFromHealthKitUseCase.swift
//  TarTanning
//
//  Created by Jun on 7/26/25.
//

import Foundation
import SwiftData
import HealthKit

@MainActor
final class SyncUVDataFromHealthKitUseCase {
    private let healthKitQueryFetchManager = HealthKitQueryFetchManager.shared
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// HealthKit에서 오늘 일광시간 데이터를 동기화하여 UVExposeRecord로 저장
    func syncTodaySunlightFromHealthKit() async throws {
        print("🔄 [SyncUVDataFromHealthKitUseCase] Syncing today's sunlight data from HealthKit")
        
        // 1. HealthKit에서 오늘의 모든 샘플 가져오기
        let samples = try await fetchTodaySamplesFromHealthKit()
        
        // 2. 기존 오늘 데이터가 있으면 삭제
        try await clearTodayUVData()
        
        // 3. 샘플들을 UVExposeRecord로 변환하여 저장
        if !samples.isEmpty {
            try await createUVExposeRecords(from: samples)
            print("✅ [SyncUVDataFromHealthKitUseCase] Successfully synced \(samples.count) samples")
        } else {
            print("📭 [SyncUVDataFromHealthKitUseCase] No sunlight data found for today")
        }
    }
    
    /// HealthKit에서 특정 기간의 일광시간 데이터 동기화
    func syncSunlightFromHealthKit(from startDate: Date, to endDate: Date) async throws {
        print("🔄 [SyncUVDataFromHealthKitUseCase] Syncing sunlight data from \(startDate) to \(endDate)")
        
        let samples = try await fetchSamplesFromHealthKit(from: startDate, to: endDate)
        
        if !samples.isEmpty {
            try await createUVExposeRecords(from: samples)
            print("✅ [SyncUVDataFromHealthKitUseCase] Successfully synced \(samples.count) samples")
        } else {
            print("📭 [SyncUVDataFromHealthKitUseCase] No sunlight data found for the period")
        }
    }
    
    // MARK: - Private Methods
    
    /// HealthKit에서 오늘 샘플 가져오기
    private func fetchTodaySamplesFromHealthKit() async throws -> [HKQuantitySample] {
        return try await withCheckedThrowingContinuation { continuation in
            healthKitQueryFetchManager.delegate = HealthKitDelegate(continuation: continuation)
            Task {
                await healthKitQueryFetchManager.fetchTodaySamples()
            }
        }
    }
    
    /// HealthKit에서 특정 기간 샘플 가져오기
    private func fetchSamplesFromHealthKit(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        return try await withCheckedThrowingContinuation { continuation in
            healthKitQueryFetchManager.delegate = HealthKitDelegate(continuation: continuation)
            Task {
                await healthKitQueryFetchManager.fetchSamples(from: startDate, to: endDate)
            }
        }
    }
    
    /// 오늘 UV 데이터 삭제
    private func clearTodayUVData() async throws {
        let today = Calendar.current.startOfDay(for: Date())
        
        // UVExposeRecord 삭제
        let uvRecordDescriptor = FetchDescriptor<UVExposeRecord>()
        let allUVRecords = try modelContext.fetch(uvRecordDescriptor)
        
        let todayUVRecords = allUVRecords.filter { record in
            Calendar.current.isDate(record.startDate, inSameDayAs: today)
        }
        
        for record in todayUVRecords {
            modelContext.delete(record)
        }
        
        // DailyUVExpose 삭제
        let dailyDescriptor = FetchDescriptor<DailyUVExpose>()
        let allDailyData = try modelContext.fetch(dailyDescriptor)
        
        let todayDailyData = allDailyData.filter { daily in
            Calendar.current.isDate(daily.date, inSameDayAs: today)
        }
        
        for daily in todayDailyData {
            modelContext.delete(daily)
        }
        
        try modelContext.save()
        print("🗑️ [SyncUVDataFromHealthKitUseCase] Cleared today's UV data")
    }
    
    /// HKQuantitySample들을 UVExposeRecord로 변환하여 저장
    private func createUVExposeRecords(from samples: [HKQuantitySample]) async throws {
        print("🔄 [SyncUVDataFromHealthKitUseCase] Converting \(samples.count) samples to UVExposeRecords")
        
        // 날짜별로 그룹화
        let groupedByDate = Dictionary(grouping: samples) { sample in
            Calendar.current.startOfDay(for: sample.startDate)
        }
        
        for (date, dateSamples) in groupedByDate {
            // 해당 날짜의 DailyUVExpose 생성 또는 가져오기
            let dailyUV = try await getOrCreateDailyUVExpose(for: date)
            
            // 각 샘플을 UVExposeRecord로 변환
            for sample in dateSamples {
                let durationMinutes = sample.quantity.doubleValue(for: .minute())
                
                let uvRecord = UVExposeRecord(
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    sunlightExposureDuration: durationMinutes,
                    isSPFApplied: false // 현재는 SPF 적용 안함
                )
                
                // 관계 설정
                uvRecord.dailyExposure = dailyUV
                dailyUV.exposureRecords.append(uvRecord)
                dailyUV.totalSunlightMinutes += durationMinutes
                
                modelContext.insert(uvRecord)
                
                print("📝 [SyncUVDataFromHealthKitUseCase] Created UVExposeRecord: \(durationMinutes) minutes")
            }
        }
        
        try modelContext.save()
        print("✅ [SyncUVDataFromHealthKitUseCase] All UVExposeRecords saved")
    }
    
    /// DailyUVExpose 생성 또는 가져오기
    private func getOrCreateDailyUVExpose(for date: Date) async throws -> DailyUVExpose {
        let descriptor = FetchDescriptor<DailyUVExpose>()
        let allDailyData = try modelContext.fetch(descriptor)
        
        let existingDaily = allDailyData.first { daily in
            Calendar.current.isDate(daily.date, inSameDayAs: date)
        }
        
        if let existingDaily = existingDaily {
            return existingDaily
        } else {
            let newDaily = DailyUVExpose(date: date)
            modelContext.insert(newDaily)
            return newDaily
        }
    }
}

// MARK: - HealthKit Delegate

private class HealthKitDelegate: HealthKitQueryFetchManagerDelegate {
    private let continuation: CheckedContinuation<[HKQuantitySample], Error>
    
    init(continuation: CheckedContinuation<[HKQuantitySample], Error>) {
        self.continuation = continuation
    }
    
    func fetchManagerDidFetchSamples(_ samples: [HKQuantitySample]) {
        continuation.resume(returning: samples)
    }
    
    func fetchManagerDidFail(with error: HealthKitError) {
        continuation.resume(throwing: error)
    }
} 