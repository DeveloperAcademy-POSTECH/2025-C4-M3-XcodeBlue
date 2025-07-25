//
//  LocationRepository.swift
//  TarTanning
//
//  Created by Jun on 7/20/25.
//

import Foundation

protocol LocationRepository {
    func getCurrentLocation() async throws -> LocationInfo
    func requestLocationPermission() async throws
    func isLocationAuthorized() -> Bool
    func startLocationUpdates() async throws
    func stopLocationUpdates() async throws
}
