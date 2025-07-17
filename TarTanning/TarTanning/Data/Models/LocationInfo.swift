//
//  LocationInfo.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import CoreLocation
import Foundation

struct LocationInfo {
    let latitude: Double
    let longitude: Double
    let city: String  // 포항시
    var asCLLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}
