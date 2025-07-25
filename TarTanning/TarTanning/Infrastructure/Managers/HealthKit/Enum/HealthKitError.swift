//
//  HealthKitError.swift
//  TarTanning
//
//  Created by taeni on 7/15/25.
//

import Foundation

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationFailed(Error)
    case authorizationDenied
    case invalidType
    case queryFailed(Error)
    case saveFailed(Error)
    case deleteFailed(Error)
    case characteristicFailed(Error)
    case backgroundDeliveryFailed(Error)
    case observerQueryFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationFailed(let error):
            return "Authorization failed: \(error.localizedDescription)"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        case .invalidType:
            return "Invalid HealthKit type"
        case .queryFailed(let error):
            return "Query failed: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Save failed: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Delete failed: \(error.localizedDescription)"
        case .characteristicFailed(let error):
            return "Characteristic query failed: \(error.localizedDescription)"
        case .backgroundDeliveryFailed(let error):
            return "Background delivery failed: \(error.localizedDescription)"
        case .observerQueryFailed(let error):
            return "Observer query failed: \(error.localizedDescription)"
        }
    }
}
