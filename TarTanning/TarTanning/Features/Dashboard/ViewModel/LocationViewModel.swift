//
//  LocationViewModel.swift
//  TarTanning
//
//  Created by 강진 on 7/14/25.
//

import Foundation
import CoreLocation
import Combine

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()

    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var locality: String = ""
    @Published var subLocality: String = ""

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            self.locality = placemark.locality ?? ""
            self.subLocality = placemark.subLocality ?? ""
        }
    }
}
