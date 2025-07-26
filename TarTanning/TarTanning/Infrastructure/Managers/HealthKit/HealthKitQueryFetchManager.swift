//
//  HealthKitQueryFetchManager.swift
//  TarTanning
//
//  Created by taeni on 7/23/25.
//

import Foundation
import HealthKit

@MainActor
protocol HealthKitQueryFetchManagerDelegate: AnyObject {
    func fetchManagerDidFetchSamples(_ samples: [HKQuantitySample])
    func fetchManagerDidFail(with error: HealthKitError)
}

@MainActor
final class HealthKitQueryFetchManager: ObservableObject {
    weak var delegate: HealthKitQueryFetchManagerDelegate?
    private let healthStore = HKHealthStore()

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: 1. 하루 동안의 모든 샘플 가져오기
    func fetchTodaySamples() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        await fetchSamples(from: startOfDay, to: now)
    }

    // MARK: 2. 특정 기간의 모든 샘플 가져오기
    func fetchSamples(from startDate: Date, to endDate: Date) async {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            let error = HealthKitError.invalidType
            errorMessage = error.localizedDescription
            delegate?.fetchManagerDidFail(with: error)
            return
        }

        isLoading = true

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        do {
            let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: daylightType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [
                        NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
                    ]
                ) { _, results, error in
                    if let error = error {
                        continuation.resume(throwing: HealthKitError.queryFailed(error))
                    } else {
                        let quantitySamples = (results as? [HKQuantitySample]) ?? []
                        continuation.resume(returning: quantitySamples)
                    }
                }

                healthStore.execute(query)
            }

            isLoading = false
            errorMessage = nil
            delegate?.fetchManagerDidFetchSamples(samples)

        } catch {
            let hkError = (error as? HealthKitError) ?? HealthKitError.queryFailed(error)
            isLoading = false
            errorMessage = hkError.localizedDescription
            delegate?.fetchManagerDidFail(with: hkError)
        }
    }

    // MARK: 3. 특정 시점부터 N개의 샘플 가져오기
    func fetchSamples(from startDate: Date, limit: Int) async {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else {
            let error = HealthKitError.invalidType
            errorMessage = error.localizedDescription
            delegate?.fetchManagerDidFail(with: error)
            return
        }

        isLoading = true

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: nil, // future 제한 없이
            options: .strictStartDate
        )

        do {
            let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: daylightType,
                    predicate: predicate,
                    limit: limit,
                    sortDescriptors: [
                        NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
                    ]
                ) { _, results, error in
                    if let error = error {
                        continuation.resume(throwing: HealthKitError.queryFailed(error))
                    } else {
                        let quantitySamples = (results as? [HKQuantitySample]) ?? []
                        continuation.resume(returning: quantitySamples)
                    }
                }

                healthStore.execute(query)
            }

            isLoading = false
            errorMessage = nil
            delegate?.fetchManagerDidFetchSamples(samples)

        } catch {
            let hkError = (error as? HealthKitError) ?? HealthKitError.queryFailed(error)
            isLoading = false
            errorMessage = hkError.localizedDescription
            delegate?.fetchManagerDidFail(with: hkError)
        }
    }
}
