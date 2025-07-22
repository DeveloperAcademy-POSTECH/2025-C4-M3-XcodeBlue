//
//  DefaultUVExposureRepository.swift
//  TarTanning
//
//  Created by Jun on 7/22/25.
//

import Foundation
import HealthKit

class DefaultUVExposureRepository: UVExposureRepository {
    private let fetchManager = HealthKitQueryFetchManager()
    private var fetchContinuation: CheckedContinuation<[HKQuantitySample], Error>?
    private var fetchDelegate: HealthKitQueryFetchManagerDelegate?

    func getTodayUVExposure() async throws -> DailyUVExpose {
        let samples = try await fetchTodaySamplesAsync()
        let records = samples.map { sample in
            UVExposeRecord(
                startDate: sample.startDate,
                endDate: sample.endDate,
                sunlightExposureDuration: sample.quantity.doubleValue(for: .minute()),
                isSPFApplied: false // 실제로는 HealthKit에서 SPF 여부를 저장하지 않으므로 false로 기본 처리
            )
        }
        let daily = DailyUVExpose(date: Date())
        daily.exposureRecords = records
        daily.totalSunlightMinutes = records.reduce(0) { $0 + $1.sunlightExposureDuration }
        daily.totalUVDose = records.reduce(0) { $0 + $1.uvDose }
        // SwiftData 저장 예시: context.insert(daily)
        return daily
    }

    func getWeeklyUVExposure() async throws -> [DailyUVExpose] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [DailyUVExpose] = []

        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let samples = try await fetchSamplesAsync(for: date)
            let records = samples.map { sample in
                UVExposeRecord(
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    sunlightExposureDuration: sample.quantity.doubleValue(for: .minute()),
                    isSPFApplied: false
                )
            }
            let daily = DailyUVExpose(date: date)
            daily.exposureRecords = records
            daily.totalSunlightMinutes = records.reduce(0) { $0 + $1.sunlightExposureDuration }
            daily.totalUVDose = records.reduce(0) { $0 + $1.uvDose }
            weeklyData.append(daily)
        }
        return weeklyData.reversed()
    }

    func getTodayUVProgressRate(userSkinType: SkinType) async throws -> Double {
        let todayExposure = try await getTodayUVExposure()
        let maxMED = userSkinType.maxMED
        guard maxMED > 0 else { return 0.0 }
        return todayExposure.totalUVDose / maxMED
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
        // SwiftData context.insert(dailyExposure)
        // try? context.save()
    }

    func getDailyUVExposure(for date: Date) async throws -> DailyUVExpose? {
        let samples = try await fetchSamplesAsync(for: date)
        let records = samples.map { sample in
            UVExposeRecord(
                startDate: sample.startDate,
                endDate: sample.endDate,
                sunlightExposureDuration: sample.quantity.doubleValue(for: .minute()),
                isSPFApplied: false
            )
        }
        let daily = DailyUVExpose(date: date)
        daily.exposureRecords = records
        daily.totalSunlightMinutes = records.reduce(0) { $0 + $1.sunlightExposureDuration }
        daily.totalUVDose = records.reduce(0) { $0 + $1.uvDose }
        return daily
    }

    func updateDailyUVExposure(for date: Date) async throws {
        // 필요하다면 SwiftData에서 해당 날짜의 DailyUVExpose를 갱신
        // 예: context.delete(old), context.insert(new)
    }

    // MARK: - Helper (delegate → async/await 변환)
    private func fetchTodaySamplesAsync() async throws -> [HKQuantitySample] {
        try await fetchSamplesAsync(for: Date())
    }

    private func fetchSamplesAsync(for date: Date) async throws -> [HKQuantitySample] {
        return try await withCheckedThrowingContinuation { continuation in
            class Delegate: HealthKitQueryFetchManagerDelegate {
                let continuation: CheckedContinuation<[HKQuantitySample], Error>
                init(_ continuation: CheckedContinuation<[HKQuantitySample], Error>) {
                    self.continuation = continuation
                }
                func fetchManagerDidFetchSamples(_ samples: [HKQuantitySample]) {
                    continuation.resume(returning: samples)
                }
                func fetchManagerDidFail(with error: HealthKitError) {
                    continuation.resume(throwing: error)
                }
            }
            let delegate = Delegate(continuation)
            self.fetchDelegate = delegate // 프로퍼티로 유지
            self.fetchManager.delegate = delegate
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            Task { await self.fetchManager.fetchSamples(from: startOfDay, to: endOfDay) }
        }
    }
}
