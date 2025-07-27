//
//  LocationUpdateManager.swift
//  TarTanning
//
//  Created by J on 7/19/25.
//

import CoreLocation
import Foundation

protocol LocationUpdateManagerDelegate: AnyObject {
    func locationUpdateDidSucceed(_ info: LocationInfo)
    func locationUpdateDidFail(with error: Error)
}

final class LocationUpdateManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationUpdateManager()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    private var currentLocationInfo: LocationInfo?
    weak var delegate: LocationUpdateManagerDelegate?
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 500
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func startUpdatingLocation() {
        print("🔄 [LocationUpdateManager] Starting significant location changes monitoring")
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            Task { @MainActor in
                delegate?.locationUpdateDidFail(with: LocationError.noLocationFound)
            }
            return
        }

        // 이미 처리 중이면 중복 방지
        guard !geocoder.isGeocoding else { return }

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }

            if let error = error {
                Task { @MainActor in
                    self.delegate?.locationUpdateDidFail(with: LocationError.geocodingFailed(error))
                }
                return
            }

            guard let placemark = placemarks?.first else {
                Task { @MainActor in
                    self.delegate?.locationUpdateDidFail(with: LocationError.noLocationFound)
                }
                return
            }

            let newCity = placemark.locality ?? ""
            let newInfo = LocationInfo(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                city: newCity
            )

            // 도시가 같으면 무시
            if newInfo.city == self.currentLocationInfo?.city {
                print("📭 [LocationUpdateManager] Same city detected, skipping update")
                return
            }

            self.currentLocationInfo = newInfo
            print("✅ [LocationUpdateManager] Location updated successfully: \(newInfo.city)")

            Task { @MainActor in
                self.delegate?.locationUpdateDidSucceed(newInfo)
            }
        }
    }
    
    // 위치 업데이트 실패 시
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            delegate?.locationUpdateDidFail(with: error)
        }
    }
}
