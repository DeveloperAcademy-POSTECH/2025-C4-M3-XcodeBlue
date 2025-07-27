//
//  HealthKitDataQueryService.swift
//  TarTanning
//
//  Created by taeni on 7/15/25.
//

import Foundation
import HealthKit

@MainActor
protocol HealthKitQueryManagerDelegate: AnyObject {
    func queryServiceDidFetchTodaysDaylight(_ minutes: Double)
    func queryServiceDidFetchDaylightExposure(_ minutes: Double, from startDate: Date, to endDate: Date)
    func queryServiceDidFetchLatestSample(_ sample: HKQuantitySample?)
    func queryServiceDidFetchWeeklyTrend(_ statistics: [DaylightStatistic])
    func queryServiceDidFetchMonthlyTrend(_ statistics: [DaylightStatistic])
    func queryServiceDidFail(with error: HealthKitError)
}

@MainActor
final class HealthKitQueryManager: ObservableObject {
    weak var delegate: HealthKitQueryManagerDelegate?
    private let healthStore = HKHealthStore()
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func fetchTodaysDaylightExposure() async {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            let error = HealthKitError.invalidType
            errorMessage = error.localizedDescription
            delegate?.queryServiceDidFail(with: error)
            return
        }
        
        isLoading = true
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        do {
            let minutes: Double = try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsQuery(
                    quantityType: daylightType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: HealthKitError.queryFailed(error))
                    } else if let sum = statistics?.sumQuantity() {
                        let minutes = sum.doubleValue(for: HKUnit.minute())
                        continuation.resume(returning: minutes)
                    } else {
                        continuation.resume(returning: 0)
                    }
                }
                
                healthStore.execute(query)
            }
            
            isLoading = false
            errorMessage = nil
            delegate?.queryServiceDidFetchTodaysDaylight(minutes)
            
        } catch {
            let hkError = (error as? HealthKitError) ?? HealthKitError.queryFailed(error)
            isLoading = false
            errorMessage = hkError.localizedDescription
            delegate?.queryServiceDidFail(with: hkError)
        }
    }
    
    func fetchDaylightExposure(from startDate: Date, to endDate: Date) async {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            let error = HealthKitError.invalidType
            errorMessage = error.localizedDescription
            delegate?.queryServiceDidFail(with: error)
            return
        }
        
        isLoading = true
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        do {
            let minutes: Double = try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsQuery(
                    quantityType: daylightType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: HealthKitError.queryFailed(error))
                    } else if let sum = statistics?.sumQuantity() {
                        let minutes = sum.doubleValue(for: HKUnit.minute())
                        continuation.resume(returning: minutes)
                    } else {
                        continuation.resume(returning: 0)
                    }
                }
                
                healthStore.execute(query)
            }
            
            isLoading = false
            errorMessage = nil
            delegate?.queryServiceDidFetchDaylightExposure(minutes, from: startDate, to: endDate)
            
        } catch {
            let hkError = (error as? HealthKitError) ?? HealthKitError.queryFailed(error)
            isLoading = false
            errorMessage = hkError.localizedDescription
            delegate?.queryServiceDidFail(with: hkError)
        }
    }
    
    func fetchLatestDaylightSample() async {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            let error = HealthKitError.invalidType
            errorMessage = error.localizedDescription
            delegate?.queryServiceDidFail(with: error)
            return
        }
        
        isLoading = true
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        do {
            let sample: HKQuantitySample? = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: daylightType,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: HealthKitError.queryFailed(error))
                    } else {
                        let latestSample = samples?.first as? HKQuantitySample
                        continuation.resume(returning: latestSample)
                    }
                }
                
                healthStore.execute(query)
            }
            
            isLoading = false
            errorMessage = nil
            delegate?.queryServiceDidFetchLatestSample(sample)
            
        } catch {
            let hkError = (error as? HealthKitError) ?? HealthKitError.queryFailed(error)
            isLoading = false
            errorMessage = hkError.localizedDescription
            delegate?.queryServiceDidFail(with: hkError)
        }
    }
    
    func fetchWeeklyDaylightTrend() async {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            let error = HealthKitError.invalidType
            errorMessage = error.localizedDescription
            delegate?.queryServiceDidFail(with: error)
            return
        }
        
        isLoading = true
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: now, options: .strictStartDate)
        
        let interval = DateComponents(day: 1)
        let anchorDate = calendar.startOfDay(for: weekAgo)
        
        do {
            let statistics: [DaylightStatistic] = try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsCollectionQuery(
                    quantityType: daylightType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum,
                    anchorDate: anchorDate,
                    intervalComponents: interval
                )
                
                query.initialResultsHandler = { _, results, error in
                    if let error = error {
                        continuation.resume(throwing: HealthKitError.queryFailed(error))
                    } else {
                        var statistics: [DaylightStatistic] = []
                        
                        results?.enumerateStatistics(from: weekAgo, to: now) { statistic, _ in
                            let date = statistic.startDate
                            let minutes = statistic.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                            statistics.append(DaylightStatistic(date: date, minutes: minutes))
                        }
                        
                        continuation.resume(returning: statistics)
                    }
                }
                
                healthStore.execute(query)
            }
            
            isLoading = false
            errorMessage = nil
            delegate?.queryServiceDidFetchWeeklyTrend(statistics)
            
        } catch {
            let hkError = (error as? HealthKitError) ?? HealthKitError.queryFailed(error)
            isLoading = false
            errorMessage = hkError.localizedDescription
            delegate?.queryServiceDidFail(with: hkError)
        }
    }
    
    func fetchMonthlyDaylightTrend() async {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            let error = HealthKitError.invalidType
            errorMessage = error.localizedDescription
            delegate?.queryServiceDidFail(with: error)
            return
        }
        
        isLoading = true
        let calendar = Calendar.current
        let now = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: monthAgo, end: now, options: .strictStartDate)
        
        let interval = DateComponents(day: 1)
        let anchorDate = calendar.startOfDay(for: monthAgo)
        
        do {
            let statistics: [DaylightStatistic] = try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsCollectionQuery(
                    quantityType: daylightType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum,
                    anchorDate: anchorDate,
                    intervalComponents: interval
                )
                
                query.initialResultsHandler = { _, results, error in
                    if let error = error {
                        continuation.resume(throwing: HealthKitError.queryFailed(error))
                    } else {
                        var statistics: [DaylightStatistic] = []
                        
                        results?.enumerateStatistics(from: monthAgo, to: now) { statistic, _ in
                            let date = statistic.startDate
                            let minutes = statistic.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                            statistics.append(DaylightStatistic(date: date, minutes: minutes))
                        }
                        
                        continuation.resume(returning: statistics)
                    }
                }
                
                healthStore.execute(query)
            }
            
            isLoading = false
            errorMessage = nil
            delegate?.queryServiceDidFetchMonthlyTrend(statistics)
            
        } catch {
            let hkError = (error as? HealthKitError) ?? HealthKitError.queryFailed(error)
            isLoading = false
            errorMessage = hkError.localizedDescription
            delegate?.queryServiceDidFail(with: hkError)
        }
    }
    
    private func fetchDaylightExposureInternal(from startDate: Date, to endDate: Date) async throws -> Double {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            throw HealthKitError.invalidType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: daylightType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                } else if let sum = statistics?.sumQuantity() {
                    let minutes = sum.doubleValue(for: HKUnit.minute())
                    continuation.resume(returning: minutes)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            
            healthStore.execute(query)
        }
    }
}
