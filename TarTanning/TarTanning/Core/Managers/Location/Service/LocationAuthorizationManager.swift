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
    weak var delegate: LocationAuthorizationManagerDelegate?
    
    private let locationManager = CLLocationManager()
    
    @Published var authorizationStatus: LocationAuthStatus = .notDetermined
    @Published var errorMessage: String?
    
    var isAuthorized: Bool {
        authorizationStatus.isAuthorized
    }
    
    override init() {
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
        Task.detached {
            let servicesEnabled = CLLocationManager.locationServicesEnabled()

            await MainActor.run {
                guard servicesEnabled else {
                    self.updateStatus(.notAvailable, error: LocationError.servicesDisabled)
                    return
                }

                guard self.locationManager.authorizationStatus == .notDetermined else {
                    self.checkAuthorizationStatus()
                    return
                }

                self.locationManager.requestWhenInUseAuthorization()
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
