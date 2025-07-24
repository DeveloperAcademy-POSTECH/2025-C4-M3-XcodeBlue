import Foundation
import CoreLocation

@MainActor
final class RealLocationRepository: NSObject, LocationRepository {
    private let authManager = LocationAuthorizationManager()
    private let updateManager = LocationUpdateManager()
    
    private var currentInfo: LocationInfo?
    private var continuation: CheckedContinuation<LocationInfo, Error>?
    
    override init() {
        super.init()
        authManager.delegate = self
        updateManager.delegate = self
    }

    func requestLocationPermission() async throws {
        try await authManager.requestAuthorization()
    }

  @MainActor func isLocationAuthorized() -> Bool {
      return authManager.isAuthorized
    }

    func startLocationUpdates() async throws {
        updateManager.startUpdatingLocation()
    }

    func stopLocationUpdates() async throws {
        updateManager.stopUpdatingLocation()
    }

    func getCurrentLocation() async throws -> LocationInfo {
        try await requestLocationPermission()
        try await startLocationUpdates()
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }
}

extension RealLocationRepository: LocationAuthorizationManagerDelegate {
    func locationAuthorizationDidSucceed() {
        // Do nothing
    }

    func locationAuthorizationDidFail(with error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func locationAuthorizationStatusDidUpdate(_ status: LocationAuthStatus) {}
}

extension RealLocationRepository: LocationUpdateManagerDelegate {
    func locationUpdateDidSucceed(_ info: LocationInfo) {
        continuation?.resume(returning: info)
        continuation = nil
    }

    func locationUpdateDidFail(with error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
