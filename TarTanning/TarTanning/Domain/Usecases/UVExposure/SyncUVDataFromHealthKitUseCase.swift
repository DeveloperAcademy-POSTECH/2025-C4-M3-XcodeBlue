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
    private let healthKitAuthorizationManager = HealthKitAuthorizationManager()
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// HealthKit에서 오늘 일광시간 데이터를 동기화하여 UVExposeRecord로 저장
    func syncTodaySunlightFromHealthKit() async throws {
        print("🔄 [SyncUVDataFromHealthKitUseCase] Syncing today's sunlight data from HealthKit")
        
        // 0. HealthKit 권한 확인 및 요청
        print("🔐 [SyncUVDataFromHealthKitUseCase] Checking HealthKit authorization status...")
        
        // 현재 권한 상태 확인
        healthKitAuthorizationManager.checkAuthorizationStatusWithCompletion()
        
        // 권한이 없으면 요청
        if !healthKitAuthorizationManager.isAuthorized {
            print("🔄 [SyncUVDataFromHealthKitUseCase] HealthKit authorization not granted, requesting...")
            await healthKitAuthorizationManager.requestAuthorization()
        }
        
        // 최종 권한 상태 확인
        guard healthKitAuthorizationManager.isAuthorized else {
            print("❌ [SyncUVDataFromHealthKitUseCase] HealthKit authorization denied after request")
            print("🔍 [SyncUVDataFromHealthKitUseCase] Authorization status: \(healthKitAuthorizationManager.authorizationStatus.description)")
            throw HealthKitError.authorizationDenied
        }
        
        print("✅ [SyncUVDataFromHealthKitUseCase] HealthKit authorization granted")
        
        // 1. HealthKit에서 오늘의 모든 샘플 가져오기
        print("📱 [SyncUVDataFromHealthKitUseCase] Fetching today's samples from HealthKit...")
        let samples = try await fetchTodaySamplesFromHealthKit()
        print("📊 [SyncUVDataFromHealthKitUseCase] Fetched \(samples.count) samples from HealthKit")
        
        // 샘플 상세 정보 출력
        for (index, sample) in samples.enumerated() {
            let durationMinutes = sample.quantity.doubleValue(for: .minute())
            print("📝 [SyncUVDataFromHealthKitUseCase] Sample \(index + 1): \(durationMinutes) minutes (\(sample.startDate.formatted(date: .omitted, time: .shortened)) - \(sample.endDate.formatted(date: .omitted, time: .shortened)))")
        }
        
        // 2. 기존 오늘 데이터가 있으면 삭제
        print("🗑️ [SyncUVDataFromHealthKitUseCase] Clearing existing today's data...")
        try await clearTodayUVData()
        
        // 3. 샘플들을 UVExposeRecord로 변환하여 저장
        if !samples.isEmpty {
            print("💾 [SyncUVDataFromHealthKitUseCase] Creating UVExposeRecords from samples...")
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
            let delegate = HealthKitDelegate(continuation: continuation)
            healthKitQueryFetchManager.delegate = delegate
            
            Task {
                await healthKitQueryFetchManager.fetchTodaySamples()
            }
            
            // 타임아웃 설정 (10초)
            Task {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10초
                if !delegate.isContinuationResolved {
                    delegate.fetchManagerDidFail(with: HealthKitError.queryFailed(NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "HealthKit query timeout"])))
                }
            }
        }
    }
    
    /// HealthKit에서 특정 기간 샘플 가져오기
    private func fetchSamplesFromHealthKit(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = HealthKitDelegate(continuation: continuation)
            healthKitQueryFetchManager.delegate = delegate
            
            Task {
                await healthKitQueryFetchManager.fetchSamples(from: startDate, to: endDate)
            }
            
            // 타임아웃 설정 (10초)
            Task {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10초
                if !delegate.isContinuationResolved {
                    delegate.fetchManagerDidFail(with: HealthKitError.queryFailed(NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "HealthKit query timeout"])))
                }
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
        
        print("📅 [SyncUVDataFromHealthKitUseCase] Grouped by \(groupedByDate.count) dates")
        
        for (date, dateSamples) in groupedByDate {
            print("📅 [SyncUVDataFromHealthKitUseCase] Processing date: \(date.formatted(date: .abbreviated, time: .omitted)) with \(dateSamples.count) samples")
            
            // 해당 날짜의 DailyUVExpose 생성 또는 가져오기
            let dailyUV = try await getOrCreateDailyUVExpose(for: date)
            print("📊 [SyncUVDataFromHealthKitUseCase] DailyUVExpose: \(dailyUV.date.formatted(date: .abbreviated, time: .omitted))")
            
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
        
        print("💾 [SyncUVDataFromHealthKitUseCase] Saving to SwiftData...")
        try modelContext.save()
        print("✅ [SyncUVDataFromHealthKitUseCase] All UVExposeRecords saved")
        
        // 저장 후 확인
        let savedRecords = try modelContext.fetch(FetchDescriptor<UVExposeRecord>())
        let savedDaily = try modelContext.fetch(FetchDescriptor<DailyUVExpose>())
        print("📊 [SyncUVDataFromHealthKitUseCase] After save - UVExposeRecord: \(savedRecords.count), DailyUVExpose: \(savedDaily.count)")
    }
    
    /// DailyUVExpose 생성 또는 가져오기
    private func getOrCreateDailyUVExpose(for date: Date) async throws -> DailyUVExpose {
        let descriptor = FetchDescriptor<DailyUVExpose>()
        let allDailyData = try modelContext.fetch(descriptor)
        
        print("🔍 [SyncUVDataFromHealthKitUseCase] Searching for existing DailyUVExpose for \(date.formatted(date: .abbreviated, time: .omitted))")
        print("🔍 [SyncUVDataFromHealthKitUseCase] Total existing DailyUVExpose: \(allDailyData.count)")
        
        let existingDaily = allDailyData.first { daily in
            Calendar.current.isDate(daily.date, inSameDayAs: date)
        }
        
        if let existingDaily = existingDaily {
            print("✅ [SyncUVDataFromHealthKitUseCase] Found existing DailyUVExpose")
            return existingDaily
        } else {
            print("🆕 [SyncUVDataFromHealthKitUseCase] Creating new DailyUVExpose")
            let newDaily = DailyUVExpose(date: date)
            modelContext.insert(newDaily)
            print("✅ [SyncUVDataFromHealthKitUseCase] New DailyUVExpose inserted")
            return newDaily
        }
    }
}

// MARK: - HealthKit Delegate

private class HealthKitDelegate: HealthKitQueryFetchManagerDelegate {
    private let continuation: CheckedContinuation<[HKQuantitySample], Error>
    private var isResolved = false
    
    init(continuation: CheckedContinuation<[HKQuantitySample], Error>) {
        self.continuation = continuation
    }
    
    func fetchManagerDidFetchSamples(_ samples: [HKQuantitySample]) {
        guard !isResolved else { return }
        isResolved = true
        continuation.resume(returning: samples)
    }
    
    func fetchManagerDidFail(with error: HealthKitError) {
        guard !isResolved else { return }
        isResolved = true
        continuation.resume(throwing: error)
    }
    
    var isContinuationResolved: Bool {
        return isResolved
    }
} 