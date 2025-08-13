//
//  LocationManager.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private var locationManager = CLLocationManager()

    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var locality: String = ""

    private let geocoder = CLGeocoder()

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        print("🔄 [LocationManager] LocationManager initialized")
        locationManager.requestWhenInUseAuthorization()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                print("✅ [LocationManager] Location authorization granted")
                locationManager.startUpdatingLocation()
            case .notDetermined:
                print("📭 [LocationManager] Location authorization not determined")
                locationManager.requestWhenInUseAuthorization()
            case .denied:
                print("❌ [LocationManager] Location authorization denied")
            default:
                print("⚠️ [LocationManager] Location authorization status: \(manager.authorizationStatus.rawValue)")
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { 
            print("❌ [LocationManager] No location data received")
            return 
        }

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self else { return }
            
            if let error = error {
                print("❌ [LocationManager] Geocoding failed: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("❌ [LocationManager] No placemark data found")
                return
            }
            
            let newLocality = placemark.locality ?? ""

            Task { @MainActor in
                if newLocality != self.locality {
                    self.latitude = location.coordinate.latitude
                    self.longitude = location.coordinate.longitude
                    self.locality = newLocality
                    print("✅ [LocationManager] Location updated: \(newLocality)")
                }
            }
        }
    }
}
