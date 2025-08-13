import Foundation
import CoreLocation

@MainActor
protocol LocationAuthorizationManagerDelegate: AnyObject {
    func locationAuthorizationDidSucceed()
    func locationAuthorizationDidFail(with error: Error)
    func locationAuthorizationStatusDidUpdate(_ status: LocationAuthStatus)
}

@MainActor
final class LocationAuthorizationManager: NSObject, ObservableObject {
    static let shared = LocationAuthorizationManager()
    
    weak var delegate: LocationAuthorizationManagerDelegate?
    
    private let locationManager = CLLocationManager()
    
    @Published var authorizationStatus: LocationAuthStatus = .notDetermined
    @Published var errorMessage: String?
    
    var isAuthorized: Bool {
        authorizationStatus.isAuthorized
    }
    
    override private init() {
        super.init()
        locationManager.delegate = self
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        Task.detached {
            let servicesEnabled = CLLocationManager.locationServicesEnabled()

            await MainActor.run {
                guard servicesEnabled else {
                    self.updateStatus(.notAvailable, error: LocationError.servicesDisabled)
                    return
                }

                let status = self.convertStatus(self.locationManager.authorizationStatus)
                self.updateStatus(status, error: nil)
            }
        }
    }
    
    func requestAuthorization() {
        print("🔄 [LocationAuthorizationManager] Requesting location authorization")
        Task.detached {
            let servicesEnabled = CLLocationManager.locationServicesEnabled()

            await MainActor.run {
                guard servicesEnabled else {
                    print("❌ [LocationAuthorizationManager] Location services disabled")
                    self.updateStatus(.notAvailable, error: LocationError.servicesDisabled)
                    return
                }

                guard self.locationManager.authorizationStatus == .notDetermined else {
                    print("📭 [LocationAuthorizationManager] Authorization already determined, checking status")
                    self.checkAuthorizationStatus()
                    return
                }

                self.locationManager.requestAlwaysAuthorization()
            }
        }
    }
    
    func requestAlwaysAuthorization() {
        Task {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    private func convertStatus(_ clStatus: CLAuthorizationStatus) -> LocationAuthStatus {
        switch clStatus {
        case .notDetermined:
            return .notDetermined
        case .authorizedWhenInUse, .authorizedAlways:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .notAvailable
        }
    }
    
    private func updateStatus(_ status: LocationAuthStatus, error: LocationError?) {
        self.authorizationStatus = status
        self.errorMessage = error?.errorDescription
        
        // 상태별 로깅
        switch status {
        case .authorized:
            print("✅ [LocationAuthorizationManager] Location authorization granted")
        case .denied:
            print("❌ [LocationAuthorizationManager] Location authorization denied")
        case .restricted:
            print("❌ [LocationAuthorizationManager] Location authorization restricted")
        case .notDetermined:
            print("📭 [LocationAuthorizationManager] Location authorization not determined")
        case .notAvailable:
            print("❌ [LocationAuthorizationManager] Location services not available")
        }
        
        delegate?.locationAuthorizationStatusDidUpdate(status)
        
        if status == .authorized {
            delegate?.locationAuthorizationDidSucceed()
        } else if let error = error {
            delegate?.locationAuthorizationDidFail(with: error)
        } else {
            switch status {
            case .denied:
                delegate?.locationAuthorizationDidFail(with: LocationError.permissionDenied)
            case .restricted:
                delegate?.locationAuthorizationDidFail(with: LocationError.restricted)
            default:
                break
            }
        }
    }
}

extension LocationAuthorizationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            checkAuthorizationStatus()
        }
    }
}
