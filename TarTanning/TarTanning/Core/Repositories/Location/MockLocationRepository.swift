//
//  MockLocationRepository.swift
//  TarTanning
//
//  Created by Jun on 7/20/25.
//

import Foundation

class MockLocationRepository: LocationRepository {
    func getCurrentLocation() async throws -> LocationInfo {
        return LocationInfo.mockSeoul
    }
    
    func requestLocationPermission() async throws {
        
    }
    
    func isLocationAuthorized() -> Bool {
        return true
    }
    
    func startLocationUpdates() async throws {
        
    }
    
    func stopLocationUpdates() async throws {
        
    }
}
