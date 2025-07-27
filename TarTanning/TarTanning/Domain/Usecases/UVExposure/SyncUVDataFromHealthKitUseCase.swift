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
    private let getUserProfileUseCase = GetUserProfileUseCase()
    private let healthStore = HKHealthStore()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// HealthKit에서 오늘 일광시간 데이터를 동기화하여 UVExposeRecord로 저장
    func syncTodaySunlightFromHealthKit() async throws {
        print("🔄 [SyncUVDataFromHealthKitUseCase] Syncing today's sunlight data from HealthKit")
        
        // 0. HealthKit 권한 확인 및 요청
        print("🔐 [SyncUVDataFromHealthKitUseCase] Checking HealthKit authorization status...")
        
        // 직접 HealthKit 권한 상태 확인
        let isAuthorized = await checkHealthKitAuthorizationStatus()
        
        if !isAuthorized {
            print("🔄 [SyncUVDataFromHealthKitUseCase] HealthKit authorization not granted, requesting...")
            let requestSuccess = await requestHealthKitAuthorization()
            
            if !requestSuccess {
                print("❌ [SyncUVDataFromHealthKitUseCase] HealthKit authorization denied after request")
                throw HealthKitError.authorizationDenied
            }
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
            
            // 타임아웃 설정 (30초로 증가)
            Task {
                try await Task.sleep(nanoseconds: 30_000_000_000) // 30초
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
            
            // 타임아웃 설정 (30초로 증가)
            Task {
                try await Task.sleep(nanoseconds: 30_000_000_000) // 30초
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
            
            // 해당 날짜의 날씨 데이터 가져오기 (UV 지수용)
            let weatherData = try await getWeatherDataForDate(date)
            
            // 각 샘플을 UVExposeRecord로 변환
            for sample in dateSamples {
                let durationMinutes = sample.quantity.doubleValue(for: .minute())
                
                // 해당 시간대의 UV 지수 가져오기
                let sampleHour = Calendar.current.component(.hour, from: sample.startDate)
                let uvIndex = getUVIndexForHour(sampleHour, from: weatherData)
                
                // UV Dose 계산 (현재는 SPF 적용 안함)
                // 상세 디버깅 로그 추가
                print("🧮 [SyncUVDataFromHealthKitUseCase] UV Dose Calculation:")
                print("   • UV Index: \(uvIndex)")
                print("   • Duration Minutes: \(durationMinutes)")
                print("   • SPF: nil (not applied)")
                print("   • Expected calculation: (\(uvIndex) * 0.025) * (\(durationMinutes) * 60)")
                
                let uvDose = MEDCalculator.calculateUVDose(
                    uvIndex: uvIndex,
                    durationMinutes: durationMinutes,
                    spf: nil  // 현재는 SPF 적용 안함
                )
                
                print("   • Calculated UV Dose: \(String(format: "%.6f", uvDose)) J/m²")
                
                let uvRecord = UVExposeRecord(
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    sunlightExposureDuration: durationMinutes,
                    isSPFApplied: false // 현재는 SPF 적용 안함
                )
                
                // UV Dose 설정
                uvRecord.uvDose = uvDose
                
                // 관계 설정
                uvRecord.dailyExposure = dailyUV
                dailyUV.exposureRecords.append(uvRecord)
                dailyUV.totalSunlightMinutes += durationMinutes
                dailyUV.totalUVDose += uvDose
                
                modelContext.insert(uvRecord)
                
                print("📝 [SyncUVDataFromHealthKitUseCase] Created UVExposeRecord: \(durationMinutes) minutes, UV Index: \(uvIndex), UV Dose: \(String(format: "%.4f", uvDose))")
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
    
    // MARK: - HealthKit Authorization Helper Methods
    
    /// HealthKit 권한 상태 직접 확인
    private func checkHealthKitAuthorizationStatus() async -> Bool {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            print("❌ [SyncUVDataFromHealthKitUseCase] Invalid daylight type")
            return false
        }
        
        let status = healthStore.authorizationStatus(for: daylightType)
        print("🔐 [SyncUVDataFromHealthKitUseCase] HealthKit authorization status: \(status.rawValue)")
        
        switch status {
        case .sharingAuthorized:
            print("✅ [SyncUVDataFromHealthKitUseCase] HealthKit authorization granted")
            return true
        case .sharingDenied:
            print("❌ [SyncUVDataFromHealthKitUseCase] HealthKit authorization denied by user")
            return false
        case .notDetermined:
            print("❌ [SyncUVDataFromHealthKitUseCase] HealthKit authorization not determined")
            return false
        @unknown default:
            print("❌ [SyncUVDataFromHealthKitUseCase] Unknown authorization status: \(status.rawValue)")
            return false
        }
    }
    
    /// HealthKit 권한 직접 요청
    private func requestHealthKitAuthorization() async -> Bool {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            print("❌ [SyncUVDataFromHealthKitUseCase] Invalid daylight type")
            return false
        }
        
        print("🔐 [SyncUVDataFromHealthKitUseCase] Requesting HealthKit authorization...")
        
        return await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: nil, read: [daylightType]) { success, error in
                if success {
                    print("✅ [SyncUVDataFromHealthKitUseCase] HealthKit authorization granted")
                } else {
                    print("❌ [SyncUVDataFromHealthKitUseCase] HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                }
                continuation.resume(returning: success)
            }
        }
    }
    
    // MARK: - Weather Data Helper Methods
    
    /// 특정 날짜의 날씨 데이터 가져오기
    private func getWeatherDataForDate(_ date: Date) async throws -> LocationWeather? {
        let descriptor = FetchDescriptor<LocationWeather>()
        let allWeatherData = try modelContext.fetch(descriptor)
        
        // 해당 날짜의 날씨 데이터 찾기
        let targetWeather = allWeatherData.first { weather in
            Calendar.current.isDate(weather.date, inSameDayAs: date)
        }
        
        if let weather = targetWeather {
            print("🌤️ [SyncUVDataFromHealthKitUseCase] Found weather data for \(date.formatted(date: .abbreviated, time: .omitted))")
        } else {
            print("⚠️ [SyncUVDataFromHealthKitUseCase] No weather data found for \(date.formatted(date: .abbreviated, time: .omitted))")
        }
        
        return targetWeather
    }
    
    /// 특정 시간의 UV 지수 가져오기
    private func getUVIndexForHour(_ hour: Int, from weatherData: LocationWeather?) -> Double {
        guard let weather = weatherData else {
            print("⚠️ [SyncUVDataFromHealthKitUseCase] No weather data available, using default UV index 0")
            return 0.0
        }
        
        // 해당 시간의 HourlyWeather 찾기
        let hourlyWeather = weather.hourlyWeathers.first { $0.hour == hour }
        
        if let hourly = hourlyWeather {
            print("☀️ [SyncUVDataFromHealthKitUseCase] Found UV index for hour \(hour): \(hourly.uvIndex)")
            return hourly.uvIndex
        } else {
            // 가장 가까운 시간의 데이터 사용
            let sortedWeathers = weather.hourlyWeathers.sorted {
                abs($0.hour - hour) < abs($1.hour - hour)
            }
            
            if let closest = sortedWeathers.first {
                print("🔍 [SyncUVDataFromHealthKitUseCase] Using closest UV index for hour \(hour): \(closest.uvIndex) (from hour \(closest.hour))")
                return closest.uvIndex
            } else {
                print("⚠️ [SyncUVDataFromHealthKitUseCase] No hourly weather data available, using default UV index 0")
                return 0.0
            }
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
