//
//  HealthKitDataQueryService.swift
//  TarTanning
//
//  Created by taeni on 7/15/25.
//

import HealthKit

struct DaylightStatistic {
    let date: Date
    let minutes: Double
}

@MainActor
protocol HealthKitDataQueryManagerDelegate: AnyObject {
    func dataQueryDidFetchTodaysDaylight(_ minutes: Double)
    func dataQueryDidFetchWeeklyTrend(_ statistics: [DaylightStatistic])
    func dataQueryDidFail(with error: HealthKitError)
}

@MainActor
final class HealthKitDataQueryManager: ObservableObject {
    weak var delegate: HealthKitDataQueryManagerDelegate?
    private let healthStore = HKHealthStore()
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func fetchTodaysDaylightExposure() async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            let error = HealthKitError.invalidType
            errorMessage = error.localizedDescription
            delegate?.dataQueryDidFail(with: error)
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
                    quantityType: type,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: HealthKitError.queryFailed(error))
                    } else {
                        let minutes = statistics?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                        continuation.resume(returning: minutes)
                    }
                }
                healthStore.execute(query)
            }
            
            isLoading = false
            errorMessage = nil
            delegate?.dataQueryDidFetchTodaysDaylight(minutes)
            
        } catch {
            let hkError = (error as? HealthKitError) ?? HealthKitError.queryFailed(error)
            isLoading = false
            errorMessage = hkError.localizedDescription
            delegate?.dataQueryDidFail(with: hkError)
        }
    }

    func fetchWeeklyDaylightTrend() async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            let error = HealthKitError.invalidType
            errorMessage = error.localizedDescription
            delegate?.dataQueryDidFail(with: error)
            return
        }

        isLoading = true
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: now, options: .strictStartDate)
        let anchorDate = calendar.startOfDay(for: weekAgo)
        let interval = DateComponents(day: 1)

        do {
            let statistics: [DaylightStatistic] = try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsCollectionQuery(
                    quantityType: type,
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
                        results?.enumerateStatistics(from: weekAgo, to: now) { stat, _ in
                            let date = stat.startDate
                            let minutes = stat.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                            statistics.append(DaylightStatistic(date: date, minutes: minutes))
                        }
                        continuation.resume(returning: statistics)
                    }
                }
                
                healthStore.execute(query)
            }
            
            isLoading = false
            errorMessage = nil
            delegate?.dataQueryDidFetchWeeklyTrend(statistics)
            
        } catch {
            let hkError = (error as? HealthKitError) ?? HealthKitError.queryFailed(error)
            isLoading = false
            errorMessage = hkError.localizedDescription
            delegate?.dataQueryDidFail(with: hkError)
        }
    }
}
