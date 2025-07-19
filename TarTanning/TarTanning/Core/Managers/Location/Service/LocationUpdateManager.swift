//
//  LocationUpdateManager.swift
//  TarTanning
//
//  Created by J on 7/19/25.
//

import CoreLocation
import Foundation

@MainActor
protocol LocationUpdateManagerDelegate: AnyObject {
    func locationUpdateDidSucceed(_ info: LocationInfo)
    func locationUpdateDidFail(with error: Error)
}

final class LocationUpdateManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    private var currentLocationInfo: LocationInfo?
    weak var delegate: LocationUpdateManagerDelegate?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // 위치 업데이트 성공 시
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            Task { @MainActor in
                delegate?.locationUpdateDidFail(with: LocationError.noLocationFound)
            }
            return
        }
        
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
            
            // 시 단위가 동일하면 무시 (업데이트 X)
            if newInfo.city == self.currentLocationInfo?.city {
                return
            }
            
            self.currentLocationInfo = newInfo
            
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
