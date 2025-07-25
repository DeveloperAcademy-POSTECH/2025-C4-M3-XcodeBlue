//
//  HealthKitBackgroundService.swift
//  TarTanning
//
//  Created by taeni on 7/15/25.
//

import Foundation
import HealthKit

@MainActor
protocol HealthKitBackgroundManagerDelegate: AnyObject {
    func backgroundDeliveryDidEnable(for type: HKObjectType)
    func backgroundDeliveryDidDisable(for type: HKObjectType)
    func observerQueryDidUpdate(for type: HKSampleType)
    func healthKitBackgroundServiceDidFail(with error: HealthKitError)
}

@MainActor
final class HealthKitBackgroundManager: ObservableObject {
    weak var delegate: HealthKitBackgroundManagerDelegate?
    
    private let healthStore = HKHealthStore()
    private var activeObserverQueries: Set<HKObserverQuery> = []
    
    @Published var isBackgroundDeliveryEnabled: Bool = false
    @Published var lastObservedType: HKSampleType?
    @Published var errorMessage: String?

    func enableBackgroundDelivery(for type: HKObjectType, frequency: HKUpdateFrequency) async {
        do {
            let success: Bool = try await withCheckedThrowingContinuation { continuation in
                healthStore.enableBackgroundDelivery(for: type, frequency: frequency) { success, error in
                    if let error = error {
                        continuation.resume(throwing: HealthKitError.backgroundDeliveryFailed(error))
                    } else {
                        continuation.resume(returning: success)
                    }
                }
            }
            
            isBackgroundDeliveryEnabled = success
            if success {
                errorMessage = nil
                delegate?.backgroundDeliveryDidEnable(for: type)
            } else {
                let error = HealthKitError.backgroundDeliveryFailed(NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Enable background delivery returned false"]))
                errorMessage = error.localizedDescription
                delegate?.healthKitBackgroundServiceDidFail(with: error)
            }
            
        } catch {
            let hkError = (error as? HealthKitError) ?? HealthKitError.backgroundDeliveryFailed(error)
            isBackgroundDeliveryEnabled = false
            errorMessage = hkError.localizedDescription
            delegate?.healthKitBackgroundServiceDidFail(with: hkError)
        }
    }
    
    func disableBackgroundDelivery(for type: HKObjectType) async {
        do {
            let success: Bool = try await withCheckedThrowingContinuation { continuation in
                healthStore.disableBackgroundDelivery(for: type) { success, error in
                    if let error = error {
                        continuation.resume(throwing: HealthKitError.backgroundDeliveryFailed(error))
                    } else {
                        continuation.resume(returning: success)
                    }
                }
            }
            
            isBackgroundDeliveryEnabled = !success
            if success {
                errorMessage = nil
                delegate?.backgroundDeliveryDidDisable(for: type)
            } else {
                let error = HealthKitError.backgroundDeliveryFailed(NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Disable background delivery returned false"]))
                errorMessage = error.localizedDescription
                delegate?.healthKitBackgroundServiceDidFail(with: error)
            }
            
        } catch {
            let hkError = (error as? HealthKitError) ?? HealthKitError.backgroundDeliveryFailed(error)
            errorMessage = hkError.localizedDescription
            delegate?.healthKitBackgroundServiceDidFail(with: hkError)
        }
    }
    
    func setupObserverQuery(for type: HKSampleType) {
        let observerQuery = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
            defer { completionHandler() }
            Task { @MainActor in
                if let error = error {
                    self?.errorMessage = HealthKitError.observerQueryFailed(error).localizedDescription
                    self?.delegate?.healthKitBackgroundServiceDidFail(with: .observerQueryFailed(error))
                } else {
                    self?.lastObservedType = type
                    self?.delegate?.observerQueryDidUpdate(for: type)
                }
            }
        }
        
        activeObserverQueries.insert(observerQuery)
        healthStore.execute(observerQuery)
    }
    
    func stopAllObserverQueries() {
        activeObserverQueries.forEach { healthStore.stop($0) }
        activeObserverQueries.removeAll()
    }
}
